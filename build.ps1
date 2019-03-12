param(
  $ubuntuVersion = '18.04',
  $varFile = 'ubuntu-server',
  $builderType = 'hyperv-iso',
  $packerVersion = '1.3.3',
  [Switch]$forcePackerDownload
)

$dir = Resolve-Path -Path "${PSScriptRoot}/build"
$packerArchive = "${PSScriptRoot}/bin/packer.zip"
$packerExe = "${PSScriptRoot}/bin/packer.exe"

mkdir -Force "${PSScriptRoot}/bin" | Out-Null

if (!(Test-Path $packerExe) -or $forcePackerDownload)
{
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest `
    -UseBasicParsing `
    -Uri "https://releases.hashicorp.com/packer/${packerVersion}/packer_${packerVersion}_windows_amd64.zip" `
    -OutFile ${packerArchive}
  
  Expand-Archive -Path ${packerArchive} -DestinationPath "${PSScriptRoot}/bin" -Force
}

Push-Location ${dir}
&$packerExe build `
  -only="${builderType}" `
  -force `
  -var-file="packer_templates\${ubuntuVersion}\${varFile}.json" `
  "packer_templates\${ubuntuVersion}\ubuntu.json"

Pop-Location