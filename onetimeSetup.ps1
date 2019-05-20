[CmdletBinding()]
param(
    [string]$aws_access_key_id,
    [string]$aws_secret_access_key,
    [string]$vagrant_cloud_username,
    [string]$vagrant_cloud_token,
    [string]$profile = 'wasabi',
    [string]$region = 'us-east-1',
    [string]$bucketName = 'rz-test-bucket',
    [string]$endpointUrl = 'https://s3.wasabisys.com'
)

pip install awscli awscli-plugin-endpoint

aws configure set plugins.endpoint awscli_plugin_endpoint
aws configure set aws_access_key_id $aws_access_key_id --profile $profile
aws configure set aws_secret_access_key $aws_secret_access_key --profile $profile
aws configure set region $region --profile $profile
aws configure set output json --profile $profile
aws configure set s3.endpoint_url $endpointUrl --profile $profile
aws configure set s3api.endpoint_url $endpointUrl --profile $profile

aws s3api create-bucket `
    --bucket "${bucketName}-private" `
    --profile $profile

aws s3api create-bucket `
    --bucket $bucketName `
    --profile $profile

@{
    Version = '2012-10-17'
    Statement = @(
        @{
            Sid = 'AllowPublicRead'
            Effect = 'Allow'
            Principal = @{
                AWS = '*'
            }
            Action = @(
                's3:GetObject',
                's3:ListBucket'
            )
            Resource = @(
                "arn:aws:s3:::$($bucketName)"
                "arn:aws:s3:::$($bucketName)/*"
            )
        }
    )
} | ConvertTo-Json -Depth 4 `
  | Out-File $PSScriptRoot/policy.json -Encoding utf8 -Force

aws s3api put-bucket-policy `
    --bucket $bucketName `
    --profile $profile `
    --policy file://$PSScriptRoot/policy.json

Remove-Item $PSScriptRoot/policy.json

[System.Environment]::SetEnvironmentVariable('VAGRANT_CLOUD_TOKEN', $vagrant_cloud_token, 'user')
[System.Environment]::SetEnvironmentVariable('VAGRANT_CLOUD_USERNAME', $vagrant_cloud_username, 'user')
[System.Environment]::SetEnvironmentVariable('VAGRANT_DEFAULT_PROVIDER', 'hyperv', 'user')

# Ensure VM Switch Exists.
if (-not (Get-VMSwitch -Name Private))
{
    New-VMSwitch -Name Private -SwitchType Internal
}