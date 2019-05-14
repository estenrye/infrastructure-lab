[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$artifactName,
  [switch]$all,
  [switch]$upload,
  [switch]$publish,
  [switch]$release,
  [string]$vagrant_cloud_token = $env:VAGRANT_CLOUD_TOKEN
)

Push-Location ${PSScriptRoot}

$manifest = Get-Content "build/images/${artifactName}/manifest.json" -Raw | ConvertFrom-Json
$data = $manifest.builds[0].custom_data
$vagrant_box_name = $data.vagrant_box_name
$vagrant_box_version = $data.vagrant_box_version
$vagrant_provider_type = $data.vagrant_provider_type
$vagrant_cloud_username = $data.vagrant_cloud_username
$vagrant_api = $data.vagrant_cloud_endpoint

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
  s3_endpoint = $data.s3_endpoint
  s3_bucket = $data.s3_bucket
  s3_profile = $data.s3_profile
  powershell_version = $PSVersionTable.PSVersion.ToString()
} | ConvertTo-Json)

if ([string]::IsNullOrWhiteSpace($vagrant_cloud_token))
{
  Write-Error "vagrant_cloud_token cannot be null or whitespace.`nThis value can be set by supplying the -vagrant_cloud_token argument or by setting $env:VAGRANT_CLOUD_TOKEN"
  return -1
}

if ($PSVersionTable.PSVersion.Major -lt 6)
{
  Write-Error "This script uses Powershell Core Cmdlets.  Powershell Major Version must be 6 or higher."
  return -1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (${upload} -or ${all})
{
  Write-Debug $(@{
    boxfile = $data.box_src_path
    s3Path = $data.s3_box_path
  } | ConvertTo-Json)
  aws s3 cp `
    $data.box_src_path `
    $data.s3_box_path `
    --endpoint-url=$($data.s3_endpoint) `
    --profile $($data.s3_profile)
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
      url = $data.s3_box_path.Replace("s3:/", $data.s3_endpoint)
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