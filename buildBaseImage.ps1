param(
  $ubuntuVersion = '18.04',
  $varFile = 'ubuntu-server',
  $builderType = 'hyperv-iso',
  $packerVersion = '1.3.5',
  [Switch]$forcePackerDownload,
  [Switch]$debug
)

Push-Location $PSScriptRoot
$packerArchive = "./bin/packer_${packerVersion}.zip"
$packerExe = "./bin/packer_${packerVersion}/packer.exe"

mkdir -Force "./bin/packer_${packerVersion}" | Out-Null

if (!(Test-Path $packerExe) -or $forcePackerDownload)
{
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest `
    -UseBasicParsing `
    -Uri "https://releases.hashicorp.com/packer/${packerVersion}/packer_${packerVersion}_windows_amd64.zip" `
    -OutFile ${packerArchive}
  
  Expand-Archive -Path ${packerArchive} -DestinationPath "./bin/packer_${packerVersion}" -Force
}

$providerType = ''
Switch($builderType)
{
  "hyperv-iso" { $providerType = "hyperv" }
  "virtualbox-iso" { $providerType = "virtualbox" }
  default { $providerType = $builderType }
}

Push-Location ${dir}
if ($debug)
{
  $env:PACKER_LOG = 1
  &$packerExe build `
    -only="${builderType}" `
    -force `
    -var-file="build/packer_templates/${ubuntuVersion}/${varFile}.json" `
    -var "providerType=${providerType}" `
    "build/packer_templates/${ubuntuVersion}/ubuntu.json"
}
else
{
  $env:PACKER_LOG = 0
  &$packerExe build `
    -only="${builderType}" `
    -force `
    -var-file="build/packer_templates/${ubuntuVersion}/${varFile}.json" `
    -var "providerType=${providerType}" `
    "build/packer_templates/${ubuntuVersion}/ubuntu.json"
}

Pop-Location