[CmdletBinding()]
param()

Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

([adsi]"WinNT://./Hyper-V Administrators,group").Add("WinNT://$env:UserDomain/$env:Username,user")

