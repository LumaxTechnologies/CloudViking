# Technical Prerequisites

You need to install the technical prerequisites :

- conda
- Ansible
- Terraform

### Conda

#### On Linux

open a Terminal, then run following commands :

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda
eval "$($HOME/miniconda/bin/conda shell.bash hook)"
conda init
```

#### On MacOS

Install conda on MacOS (you will be prompted for admin password at some moments).

First, open a Terminal, then run following commands :

```bash
mkdir -p ~/miniconda3
curl https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
~/miniconda3/bin/conda init bash
~/miniconda3/bin/conda init zsh
```

### Python environment - configuration

Create a conda virtual environment :

```bash
cd <WORKFOLDER> ### move to your workfolder
conda create -n cloudviking python=3.11 ### this command create a local environment in python 3.11
```

Now, activate the python 3.11 environment you just created :

```bash
conda activate cloudviking
```

This command will add the name of the environment between parenthesis on your command line prompt.

If you need to exit from the conda environment, simply run :

```bash
conda deactivate
```

### Terraform

[Terraform](https://www.terraform.io/) is an Infrastructure as Code tool developed by HashiCorp.

On ubuntu/debian be sure you have all dependencies :

```bash
sudo apt install curl lsb-release software-properties-common
```

Then follow the instructions for your OS [here](https://www.terraform.io/downloads)

#### On Ubuntu/Debian

Install with :

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

#### On MacOS

Install with :

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Ansible

[Ansible](https://www.ansible.com/) is a Configuration Management tool that allows parallelized SSH connections to remote hosts and management of various remote commands.

You can install Ansible through pip in your current python environment with the following commands :

```bash
pip3 install ansible
```

## Credentials

## AWS Credentials

Create an SSH API credentials in AWS Portal, then be sure to create the file `credentials/aws/.env`

This file should have the following structure :

```.env
export TF_VAR_aws_access_key_id=<YOUR_AWS_ACCESSS_KEY>
export TF_VAR_aws_secret_access_key=<YOUR_AWS_SECRET_KEY>
```

## Azure Credentials

Configure the Azure credentials :

```bash
cd credentials/azure
touch .env
```

Then set the `.env` file with your Azure API credentials, with this structure :

```.env
export CREDENTIALS=$(pwd)/credentials/azure
export SERVICE_PRINCIPAL=$CREDENTIALS/service_principal.json
export SUBSCRIPTION_ID=$(cat $CREDENTIALS/az_account.json | grep subscriptionId | cut -d '"' -f 4)
export TF_VAR_subscription_id=$(cat $CREDENTIALS/az_account.json | grep subscriptionId | cut -d '"' -f 4)
export TF_VAR_client_id=$(cat $SERVICE_PRINCIPAL | grep appId | cut -d '"' -f 4)
export TF_VAR_client_secret=$(cat $SERVICE_PRINCIPAL | grep password | cut -d '"' -f 4)
export TF_VAR_tenant_id=$(cat $SERVICE_PRINCIPAL | grep tenant | cut -d '"' -f 4)
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
export ARM_CLIENT_ID=$(cat $SERVICE_PRINCIPAL | grep appId | cut -d '"' -f 4)
export ARM_CLIENT_SECRET=$(cat $SERVICE_PRINCIPAL | grep password | cut -d '"' -f 4)
export ARM_TENANT_ID=$(cat $SERVICE_PRINCIPAL | grep tenant | cut -d '"' -f 4)
export ARM_ENVIRONMENT=public
export TF_VAR_region=eastus
```

For Azure, you also need to create a file `az_account.json` :

```json
{
	"subscriptionId": "XXX",
	"tenantId": "XXX"
  }
```

and a file `service_principal.json` :

```json
{
	"appId": "XXX",
	"displayName": "XXX",
	"name": "XXX",
	"password": "XXX",
	"tenant": "XXX"
}  
```

Use an Azure Cloud CLI in the Azure portal to get the information to fill these files.

Commands to use in the Azure Cloud CLI :

```bash
az account show --query "{subscriptionId:id, tenantId:tenantId}"
export SUBSCRIPTION_ID=$(az account show --query "{subscriptionId:id, tenantId:tenantId}" | grep subscriptionId | cut -d '"' -f 4)
```

Then

```bash
az account set --subscription="${SUBSCRIPTION_ID}"
az ad sp create-for-rbac --role="Owner" --scopes="/subscriptions/${SUBSCRIPTION_ID}"
```

## Azure CLI

Install Azure CLI on Ubuntu :

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

Install Azure CLI on macOS :

```bash
brew update && brew install azure-cli
```

Install Azure CLI on Windows :

1. Download the installer from: https://aka.ms/installazurecliwindows
2. Run the downloaded `.msi` file and follow the prompts to complete the installation.

For more details, see the [official Azure CLI install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

## AWS CLI

Install AWS CLI on Ubuntu/Debian :

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws
```

To verify the installation:

```bash
aws --version
```

If you need to upgrade or uninstall, see the [official AWS CLI Linux install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

Install AWS CLI on macOS :

```bash
brew update && brew install awscli
```

Install AWS CLI on Windows :

1. Download the installer from: https://awscli.amazonaws.com/AWSCLIV2.msi
2. Run the downloaded `.msi` file and follow the prompts to complete the installation.

For more details, see the [official AWS CLI install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

## Return to README

Now, go back to the main README [here](../README.md)