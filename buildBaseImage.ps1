param(
  $ubuntuVersion = '18.04',
  $varFile = 'ubuntu-server',
  $builderType = 'hyperv-iso',
  $packerVersion = '1.4.0',
  [Switch]$forcePackerDownload,
  [Switch]$debug
)

Push-Location $PSScriptRoot
$packerArchive = "./bin/packer.zip"
$packerExe = "./bin/packer.exe"

mkdir -Force "./bin" | Out-Null

if (!(Test-Path $packerExe) -or $forcePackerDownload)
{
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest `
    -UseBasicParsing `
    -Uri "https://releases.hashicorp.com/packer/${packerVersion}/packer_${packerVersion}_windows_amd64.zip" `
    -OutFile ${packerArchive}
  
  Expand-Archive -Path ${packerArchive} -DestinationPath "./bin" -Force
}

Push-Location ${dir}
if ($debug)
{
  $env:PACKER_LOG = 1
  &$packerExe build `
    -only="${builderType}" `
    -force `
    -debug `
    -var-file="build/packer_templates/${ubuntuVersion}/${varFile}.json" `
    "build/packer_templates/${ubuntuVersion}/ubuntu.json"
}
else
{
  &$packerExe build `
    -only="${builderType}" `
    -force `
    -var-file="build/packer_templates/${ubuntuVersion}/${varFile}.json" `
    "build/packer_templates/${ubuntuVersion}/ubuntu.json"
}

Pop-Location