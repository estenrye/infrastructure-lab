[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$machineType,
    [string]$bucketName = 'vagrant-cloud',
    [string]$profile='wasabi'
)

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