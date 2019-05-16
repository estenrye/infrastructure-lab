[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$machineType
)

if ($DebugPreference)
{
    $env:PACKER_LOG=1
}
else
{
    $env:PACKER_LOG=0
}

Push-Location ${PSScriptRoot}
.\bin\packer.exe `
    build `
    -force `
    -var-file ".\build\packer_templates\lab\${machineType}\${machineType}.json" `
    ".\build\packer_templates\lab\vagrant.json"

Pop-Location