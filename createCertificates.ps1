[CmdletBinding()]
param(
    [string]$bucketName = 'vagrant-cloud',
    [string]$profile='wasabi'
)

Push-Location ${PSScriptRoot}

aws s3 sync build/certificates "s3://${bucketName}-private/certificates" --profile $profile

if(-not (Test-Path build/certificates/public/domain.local.crt))
{
    if (-not (Test-Path build/certificates/private))
    {
        New-Item -ItemType Directory build/certificates/private
    }

    if (-not (Test-Path build/certificates/public))
    {
        New-Item -ItemType Directory build/certificates/public
    }

    openssl genrsa -out build/certificates/private/ca.key 2048
    openssl req -new -x509 -days 365 `
        -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=Acme Root CA" `
        -key build/certificates/private/ca.key `
        -out build/certificates/public/ca.crt
    
    openssl req -newkey rsa:2048 -nodes `
        -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=*.domain.local" `
        -keyout build/certificates/private/domain.local.key `
        -out build/certificates/private/domain.local.csr
    
    "subjectAltName=DNS:domain.local,DNS:localhost" | Out-File -Force build/certificates/private/san.config

    openssl x509 -req -days 365 `
        -extfile build/certificates/private/san.config `
        -in build/certificates/private/domain.local.csr `
        -CA build/certificates/public/ca.crt `
        -CAkey build/certificates/private/ca.key `
        -CAcreateserial `
        -CAserial build/certificates/private/serial `
        -out build/certificates/public/domain.local.crt

    aws s3 sync build/certificates "s3://${bucketName}-private/certificates" --profile $profile
    aws s3 sync build/certificates/public "s3://${bucketName}/certificates" --profile $profile
}

Pop-Location