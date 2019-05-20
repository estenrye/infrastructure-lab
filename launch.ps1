[CmdletBinding()]
param()

if ($PSVersionTable.PSVersion.Major -gt 5)
{
    Write-Error "This script uses the Hyper-V module.  This module is not supported in Powershell Core."
    return -1
}

Push-Location $PSScriptRoot

vagrant up router
if (-not (Get-VMNetworkAdapter -VMName router -Name LAN -ErrorAction SilentlyContinue))
{
    vagrant halt router
    Add-VMNetworkAdapter -VMName router -SwitchName Private -Name LAN
    Start-VM router
}

vagrant up dc, manager, worker

Pop-Location