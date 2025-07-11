# CloudViking

A simple tool to manage cloud architectures with Terraform and Ansible

## First time prerequisites

See the first time technical prerequisites [here](./doc/prerequisites.md)

## Setup a new customer

### Create a dedicated SSH Key pair

Make all of your scripts executable :

```bash
chmod +x *.sh
```

Set your customer's name :

```bash
export CUSTOMER=<YOUR_CUSTOMER_NAME> ### set the name here
``` 

Generate a SSH Key pair :

```bash
./generate_ssh_keys.sh $CUSTOMER
```

### Configure the deployments file

<!-- Once you have setup a `credentials/.env` file, you can start deploying resources -->

Have a look at file `deployments/deployments.yml`, it has the following structure :

```yaml
customers:
  internal:
    environments:
    - terraform_backend
    provider: azure
  <CUSTOMER>:
    customize:
      <FIRST_ENVIRONMENT>:
        current_environment: development
      <SECOND_ENVIRONMENT>:
        current_environment: production
    environments:
    - common
    - <FIRST_ENVIRONMENT>
    - <SECOND_ENVIRONMENT>
    provider: azure
```

- An "environment" is a full stack of the target architecture
- A "customer" can have several environments
- The "internal" customer is for managing resources shared by the whole company
- "<CUSTOMER>.environments.common" is a special "environment" hosting the permanent public frontend, associated with a public DNS, + a permanent VPC hosting all private subnets of all customers
- Thus, "common" is a reserved name for extra environments, and you need a "common" environment per customer.
- "<CUSTOMER>.customize" is a way to override the default parameters of an environment. See [here]() for details about stack parameters. 

#### Add an extra customer

When defining the customer `CUSTOMER`, be sure to have at least the following keys in `deployments.yml` :

```yaml
customers:
  ...
  <CUSTOMER>:
    customize:
      ...
      <FIRST_ENVIRONMENT>:
        current_environment: development
      ...
    environments:
    - common
    - <FIRST_ENVIRONMENT>
    ...
    provider: azure
```

### SSH Keys

Create the SSH Keys for your environment :

```bash
./generate_ssh_keys.sh $CUSTOMER
```

## Deploying/updating a customer

### Python environment

First, be sure to have activated your conda environment :

```bash
conda activate cloudviking
```

Then, be sure to have installed python requirements for the project :

```bash
pip install -r requirements.txt
```

### Deploy the common resources

Set your customer's name :

```bash
export CUSTOMER=cloudviking ### choose your customer
```

Run the following commands :

```bash
python3 cli.py $CUSTOMER common init
python3 cli.py $CUSTOMER common tf_init
python3 cli.py $CUSTOMER common tf_apply
python3 cli.py $CUSTOMER common config
python3 cli.py $CUSTOMER common proxy
```

### Deploy an environment

Set the environment's name :

```bash
export ENVIRONMENT=dev ### choose your environment
```

Run the following commands :

```bash
python3 cli.py $CUSTOMER $ENVIRONMENT init
python3 cli.py $CUSTOMER $ENVIRONMENT tf_init
python3 cli.py $CUSTOMER $ENVIRONMENT tf_apply
python3 cli.py $CUSTOMER $ENVIRONMENT config
```


```bash
python3 cli.py $CUSTOMER $ENVIRONMENT setup
python3 cli.py $CUSTOMER $ENVIRONMENT frontend
python3 cli.py $CUSTOMER $ENVIRONMENT ssl
python3 cli.py $CUSTOMER $ENVIRONMENT guacamole
python3 cli.py $CUSTOMER $ENVIRONMENT sftp
python3 cli.py $CUSTOMER $ENVIRONMENT nifi
python3 cli.py $CUSTOMER $ENVIRONMENT route
```

## Tips and Tricks

### Direct SSH access

If you want to reach a VM in a private subnet, you can ssh into it directly with this command :

```bash
ssh -F deployments/$CUSTOMER/$ENVIRONMENT/config/ssh.cfg <HOSTNAME>
```

where `<HOSTNAME>` is the name of the remote machine in `ssh.cfg`

### Clearing VMs

If you want to destroy a Cloud VM, to recreate it if necessary, but not all of the AWS resources, you can do that :

- in `deployments/$CUSTOMER/$ENVIRONMENT/terraform/terraform.tfvars`, find the list `medium_ec2s`
- comment the machines you want to destroy
- run `terraform apply` in `terraform` folder. It will propose to destroy the commented machine
- uncomment the machines
- run `terraform apply` again to recreate them
- run `configure.sh` in root folder again to update IP addresses everywhere in `config` folder
- you are done !

__WARNING__ : wait for the newly created VM to finish full startup before trying to reach it through SSH (or Ansible). Terraform will finish it process *before* the VMs are all fully online.
