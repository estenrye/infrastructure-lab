[CmdletBinding()]
param(
  $vagrant_box_name = $env:VAGRANT_BOX_NAME,
  $vagrant_box_version = $(if([string]::IsNullOrWhiteSpace($env:VAGRANT_BOX_VERSION))
                           { Get-Date -Format "yyyy.MM.dd" }
                           else
                           { $env:VAGRANT_BOX_VERSION }
                          ),
  $vagrant_provider_type = $(if([string]::IsNullOrWhiteSpace($env:VAGRANT_PROVIDER_TYPE))
                             { 'hyperv' }
                             else
                             { $env:VAGRANT_PROVIDER_TYPE }
                            ),
  $vagrant_cloud_token = $env:VAGRANT_CLOUD_TOKEN,
  $vagrant_cloud_username = $env:VAGRANT_CLOUD_USERNAME,
  [switch]$publish,
  [switch]$upload,
  [switch]$release,
  [switch]$all,
  $vagrant_api = 'https://app.vagrantup.com/api/v1',
  $s3_endpoint = 'https://s3.wasabisys.com',
  $s3_bucket = 'vagrant-cloud',
  $s3_profile = 'wasabi',
  $jq_version = '1.6'
)

Write-Debug $(@{
  vagrant_box_name = $vagrant_box_name
  vagrant_box_version = $vagrant_box_version
  vagrant_provider_type = $vagrant_provider_type
  vagrant_cloud_token = $vagrant_cloud_token
  vagrant_cloud_username = $vagrant_cloud_username
  publish = $publish
  upload = $upload
  release = $release
  vagrant_api = $vagrant_api
  s3_endpoint = $s3_endpoint
  s3_bucket = $s3_bucket
  s3_profile = $s3_profile
  jq_version = $jq_version
  powershell_version = $PSVersionTable.PSVersion.ToString()
} | ConvertTo-Json)

if([string]::IsNullOrWhiteSpace($vagrant_box_name))
{ 
  Write-Error "vagrant_box_name cannot be null or whitespace."
  return -1
}

if ([string]::IsNullOrWhiteSpace($vagrant_cloud_token))
{
  Write-Error "vagrant_cloud_token cannot be null or whitespace"
  return -1
}

if ([string]::IsNullOrWhiteSpace($env:VAGRANT_CLOUD_USERNAME))
{
  Write-Error "vagrant_cloud_username cannot be null or whitespace."
  return -1
}

if ($PSVersionTable.PSVersion.Major -lt 6)
{
  Write-Error "Powershell version must be 6 or higher."
  return -1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dir = Resolve-Path -Path "${PSScriptRoot}/build"
Push-Location ${dir}

$manifest = Get-Content manifest.json -Raw | ConvertFrom-Json
$box = $(${manifest}.builds | `
         Where-Object { $_.artifact_id -eq ${vagrant_provider_type} })[0]
$boxfile = ${box}.files[0].name

$s3_box_path = "${s3_bucket}/${vagrant_box_name}/${vagrant_provider_type}-${vagrant_box_version}.box"

if (${upload} -or ${all})
{
  Write-Debug $(@{
    boxfile = "images/${boxfile}"
    s3Path = "s3://${s3_box_path}"
  } | ConvertTo-Json)
  aws s3 cp `
    "images/${boxfile}" `
    "s3://${s3_box_path}" `
    --endpoint-url=${s3_endpoint} `
    --profile ${s3_profile}
}

$box_api = "${vagrant_api}/box/${vagrant_cloud_username}/${vagrant_box_name}"
$token = ConvertTo-SecureString -String ${vagrant_cloud_token} -AsPlainText -Force
if (${publish} -or ${all})
{
  Write-Debug $(@{
    method = 'GET'
    uri = $box_api
  } | ConvertTo-Json)
  $getBox = Invoke-WebRequest `
              -UseBasicParsing `
              -Uri $box_api `
              -ContentType 'application/json' `
              -Headers ${header} `
              -Method Get `
              -Authentication Bearer `
              -Token ${token} `
              -ErrorAction SilentlyContinue

  Write-Debug $(@{
    method = 'GET'
    uri = $box_api
    statusCode = ${getBox}.StatusCode
  } | ConvertTo-Json)
  
  if (${getBox}.StatusCode -ne 200)
  {
    $body = @{
      box = @{
        username = ${vagrant_cloud_username}
        name = ${vagrant_box_name}
        is_private = $false
      }
    } | ConvertTo-Json

    Write-Debug $(@{
      uri = "${vagrant_api}/boxes"
      method = 'POST'
      body = $body
    } | ConvertTo-Json)
    Invoke-RestMethod `
      -UseBasicParsing `
      -Uri "${vagrant_api}/boxes" `
      -ContentType 'application/json' `
      -Headers ${header} `
      -Method Post `
      -Authentication Bearer `
      -Token ${token} `
      -Body ${body}
  }  

  Write-Debug $(@{
    method = 'GET'
    uri = "${box_api}/version/${vagrant_box_version}"
  } | ConvertTo-Json)

  $getVersion = Invoke-WebRequest `
    -UseBasicParsing `
    -Uri "${box_api}/version/${vagrant_box_version}" `
    -ContentType 'application/json' `
    -Headers ${header} `
    -Method Get `
    -Authentication Bearer `
    -Token ${token} `
    -Body ${body}

  Write-Debug $(@{
    method = 'GET'
    uri = "${box_api}/version/${vagrant_box_version}"
    statusCode = ${getVersion}.StatusCode
  } | ConvertTo-Json)

  if (${getVersion}.StatusCode -ne 200)
  {
    $body = @{
      version = @{
        version = ${vagrant_box_version}
      }
    } | ConvertTo-Json
  
    Write-Debug $(@{
      method = 'POST'
      uri = "${box_api}/versions"
      body = $body
    } | ConvertTo-Json)

    Invoke-RestMethod `
      -UseBasicParsing `
      -Uri "${box_api}/versions" `
      -ContentType 'application/json' `
      -Headers ${header} `
      -Method Post `
      -Authentication Bearer `
      -Token ${token} `
      -Body ${body}
  }

  $provider = ($getVersion.Content `
    | ConvertFrom-Json -ErrorAction SilentlyContinue).providers `
    | Where-Object { $_.name -eq ${vagrant_provider_type} }
  
  $body = @{
    provider = @{
      name = ${vagrant_provider_type}
      url = "${s3_endpoint}/${s3_box_path}"
    }
  } | ConvertTo-Json
  
  $method = 'Post'
  $uri = "${box_api}/version/${vagrant_box_version}/providers"
  if ($provider.Length -gt 0)
  {
    $method = 'Put'
    $uri = "${box_api}/version/${vagrant_box_version}/provider/${vagrant_provider_type}"
  }

  Write-Debug $(@{
    method = $method
    uri = $uri
    body = $body
  } | ConvertTo-Json)

  Invoke-RestMethod `
    -UseBasicParsing `
    -Uri $uri `
    -ContentType 'application/json' `
    -Headers ${header} `
    -Method ${method} `
    -Authentication Bearer `
    -Token ${token} `
    -Body ${body}
}

if (${release} -or ${all})
{
  Write-Debug $(@{
    method = 'PUT'
    uri = "${box_api}/version/${vagrant_box_version}/release"
  } | ConvertTo-Json)

  Invoke-RestMethod `
    -UseBasicParsing `
    -Uri "${box_api}/version/${vagrant_box_version}/release" `
    -Headers ${header} `
    -Method Put `
    -Authentication Bearer `
    -Token ${token}
}

Pop-Location