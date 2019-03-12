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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dir = Resolve-Path -Path "${PSScriptRoot}/build"
$python_packages = $(pip show awscli | Select-String -Pattern 'Location:*')
$python_packages = ${python_packages}.ToString().Replace('Location: ', '')
$aws_cli = Resolve-Path -Path "${python_packages}/awscli"

Push-Location ${dir}

$manifest = Get-Content manifest.json -Raw | ConvertFrom-Json
$box = $(${manifest}.builds | `
         Where-Object { $_.artifact_id -eq ${vagrant_provider_type} })[0]
$boxfile = ${box}.files[0].name

$s3_box_path = "${s3_bucket}/${vagrant_box_name}/${vagrant_provider_type}-${vagrant_box_version}.box"

if (${upload} -or ${all})
{
  python ${aws_cli} s3 cp `
    "images/${boxfile}" `
    "s3://${s3_box_path}" `
    --endpoint-url=${s3_endpoint} `
    --profile ${s3_profile}
}

$box_api = "${vagrant_api}/box/${vagrant_cloud_username}/${vagrant_box_name}"
$token = ConvertTo-SecureString -String ${vagrant_cloud_token} -AsPlainText -Force
if (${publish} -or ${all})
{
  $body = @{
    box = @{
      username = ${vagrant_cloud_username}
      name = ${vagrant_box_name}
      is_private = $false
    }
  } | ConvertTo-Json

  Invoke-RestMethod `
    -UseBasicParsing `
    -Uri "${vagrant_api}/boxes" `
    -ContentType 'application/json' `
    -Headers ${header} `
    -Method Post `
    -Authentication Bearer `
    -Token ${token} `
    -Body ${body}
  
  $body = @{
    version = @{
      version = ${vagrant_box_version}
    }
  } | ConvertTo-Json

  Invoke-RestMethod `
    -UseBasicParsing `
    -Uri "${box_api}/versions" `
    -ContentType 'application/json' `
    -Headers ${header} `
    -Method Post `
    -Authentication Bearer `
    -Token ${token} `
    -Body ${body}
  
  $body = @{
    provider = @{
      name = ${vagrant_provider_type}
      uri = "${s3_endpoint}/${s3_box_path}"
    }
  } | ConvertTo-Json
  
  Invoke-RestMethod `
    -UseBasicParsing `
    -Uri "${box_api}/version/${vagrant_box_version}/providers" `
    -ContentType 'application/json' `
    -Headers ${header} `
    -Method Post `
    -Authentication Bearer `
    -Token ${token} `
    -Body ${body}
}

if (${release} -or ${all})
{
  Invoke-RestMethod `
    -UseBasicParsing `
    -Uri "${box_api}/version/${vagrant_box_version}/release" `
    -Headers ${header} `
    -Method Put `
    -Authentication Bearer `
    -Token ${token}
}

Pop-Location