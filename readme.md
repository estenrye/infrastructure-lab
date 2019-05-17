# Infrastructure Lab

## Enabling Hyper-V

1. Run `./enableHyperV.ps1` in an admin Powershell terminal.

## Setting up the publishing environment:

1. Log into your S3 admin console.
2. Create a user that has rights to create/modify buckets.
3. Sign up for Vagrant Cloud
4. Create a Vagrant Cloud authentication token.
5. Install Vagrant.
6. Run `./onetimeSetup.ps1` supplying your S3 bucket information, S3 access keys and Vagrant Cloud authentication credentials.

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