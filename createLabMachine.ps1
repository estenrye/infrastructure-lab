[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$machineType,
    [string]$bucketName = 'vagrant-cloud',
    [string]$profile='wasabi',
    [string]$packerVersion = '1.4.0',
    [Switch]$forcePackerDownload
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

if ($DebugPreference)
{
    $env:PACKER_LOG=1
    $env:VAGRANT_LOG='debug'
}
else
{
    $env:PACKER_LOG=0
    $env:VAGRANT_LOG='info'
}

Push-Location ${PSScriptRoot}
.\bin\packer.exe `
    build `
    -force `
    -var-file ".\build\packer_templates\lab\${machineType}\${machineType}.json" `
    ".\build\packer_templates\lab\vagrant.json"

Pop-Location