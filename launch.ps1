[CmdletBinding()]
param()

if ($PSVersionTable.PSVersion.Major -gt 5)
{
    Write-Error "This script uses the Hyper-V module.  This module is not supported in Powershell Core."
    return -1
}

Push-Location $PSScriptRoot

if (-not (Get-VMNetworkAdapter -VMName router -Name LAN -ErrorAction SilentlyContinue))
{
    vagrant up router
    vagrant halt router
    Add-VMNetworkAdapter -VMName router -SwitchName Private -Name LAN
    Start-VM router
}

vagrant up

Pop-Location