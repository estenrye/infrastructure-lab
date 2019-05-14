[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$machineType
)

Push-Location ${PSScriptRoot}
.\bin\packer.exe `
    build `
    -force `
    -var-file ".\build\packer_templates\lab\${machineType}\${machineType}.json" `
    ".\build\packer_templates\lab\vagrant.json"

Pop-Location