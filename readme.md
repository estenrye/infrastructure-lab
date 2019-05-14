# Infrastructure Lab

## Setting up the publishing environment:

1. Log into Wasabi admin console.
2. Create a bucket named vagrant-cloud
3. Enable public access for the bucket.
4. Apply the following policy to the bucket:

    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Sid": "AllowPublicRead",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::vagrant-cloud/*"
            }
        ]
    }
    ```
5. Create an IAM user named `vagrant-cloud`.
6. Attach the WasabiWriteOnlyAccess IAM Policy to the `vagrant-cloud` user.

# Preparing your development environment

1. Ensure a user with appropriate privileges has been provisioned on your Wasabi S3 storage.
2. Request an API key for that user.
3. Install Python 3.
4. Install the AWS CLI, `pip install awscli`
5. Edit `~/.aws/config`

    ```
    [profile wasabi]
    region = us-east-1
    output = json
    s3 =
        endpoint_url = https://s3.wasabisys.com
    ```

6. Edit `~/.aws/credentials`

    ```
    [wasabi]
    aws_access_key_id = {{ AWS ACCESS KEY HERE }}
    aws_secret_access_key = {{ AWS SECRET ACCESS KEY HERE }}
    ```

7. Sign up for a Vagrant Cloud Account.
8. Request a Vagrant Cloud API key.
9. Set the Vagrant Cloud API key as an environment variable:

    ```powershell
    [System.Environment]::SetEnvironmentVariable('VAGRANT_CLOUD_TOKEN', 'YOUR TOKEN HERE', 'user')
    ```

10. Enable Hyper-V
11. Add your Windows Account to the Hyper-V Administrators group for automation convenience.
12. Install Vagrant
13. Install Powershell Core


# Building a Base Image

1. Run `./buildBaseImage.ps1`with the desired arguments.  Example: 

    ```powershell
    ./buildBaseImage.ps1 -ubuntuVersion 18.04 -varFile ubuntu-server -builderType hyperv-iso
    ```

2. See valid argument values in the table below:

    | ubuntuVersion | varFile         | builderTypes |
    | ------------- | --------------- | ------------ |
    | `18.04`       | `ubuntu-server`, `ubuntu-desktop` | `hyperv-iso`, `virtualbox-iso` |

# Building a Lab Image

1. Run `./createLabMachine.ps1` with the desired arguments.  Example: `./createLabMachine.
# Publishing a Vagrant Image to Wasabi S3 storage

1. Run `./publish.ps1` with the desired arguments.  Example: `./publish.ps1 ubuntu-server-1804 -all`
2. See valid artifactName values below:
  - `ubuntu-server-1804`
  - `ubuntu-desktop`
  - `router`