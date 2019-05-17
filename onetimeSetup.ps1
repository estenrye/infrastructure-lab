[CmdletBinding()]
param(
    [string]$aws_access_key_id,
    [string]$aws_secret_access_key,
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
    --bucket $bucketName `
    --profile $profile `
    --endpoint-url $endpointUrl

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
} | ConvertTo-Json -Depth 4 | Out-File $PSScriptRoot/policy.json -Encoding utf8 -Force

aws s3api put-bucket-policy `
    --bucket $bucketName `
    --profile $profile `
    --endpoint-url $endpointUrl `
    --policy file://$PSScriptRoot/policy.json

Remove-Item $PSScriptRoot/policy.json