#!/usr/bin/env python
import os
import sys
import json
import shutil
import subprocess
import click
import yaml
from InquirerPy import prompt
from jinja2 import Environment, FileSystemLoader
from dotenv import load_dotenv

# Define allowed commands and mapping for ansible playbooks
ALLOWED_COMMANDS = [
    "init", "tf_init", "tf_apply", "tf_destroy", "config", "setup", "deploy", "update", "ssl", "proxy", "ocr","nifi", "route", "dev_daniel__ocr_stack", "smb", "guacamole", "sftp", "nifi",
    "up",
    "down",
    "frontend"
]

ANSIBLE_PLAYBOOKS = {
    "setup": "setup_ssh_access.yml",
    "ssl": "setup_ssl_environment.yml",
    "proxy": "setup_proxy.yml",
    "deploy": "deploy_python_app.yml",
    "update": "update_python_app.yml",
    "ocr": "setup_ocr_stack.yml",
    "nifi": "install_nifi.yml",
    "route": "configure_proxy.yml",
    "dev_daniel__ocr_stack": "dev_daniel__setup_ocr_stack.yml",
    "smb": "setup_smb.yml",
    "guacamole":"setup_apache_guacamole.yml",
    "sftp":"setup_sftp.yml",
    "nifi":"setup_nifi.yml",
    "frontend": "deploy_apps.yml"
}

PROVIDER_SPECIFIC = [
    "setup_proxy.yml"
]

APPS = [
    "SMB"
]

CUSTOM_ENVIRONMENTS = [
    "common"
]

PROVIDER_USERNAME = {
    "aws": "ec2-user",
    "azure": "azureuser"
}

def ensure_az_logged_in(customer, environment, provider):
    """
    Checks if Azure CLI is logged in. If not, runs 'az login' interactively.
    """

    load_environment(customer, environment, provider)

    try:
        # Try to get an access token (works only if already logged in)
        subprocess.run(["az", "account", "show"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print("✅ Azure CLI already logged in.")
    except subprocess.CalledProcessError:
        print("🔑 Azure CLI not logged in. Running 'az login'...")
        try:
            subprocess.run([
                "az", "login",
                "--service-principal",
                "-u", os.environ["ARM_CLIENT_ID"],
                "-p", os.environ["ARM_CLIENT_SECRET"],
                "--tenant", os.environ["ARM_TENANT_ID"]
            ], check=True)
        except subprocess.CalledProcessError as e:
            print(f"❌ 'az login' failed: {e}")
            sys.exit(1)


def handle_vm_power(customer, environment, provider, action):
    """
    Handles 'up' and 'down' commands for Azure and AWS VMs.
    Uses 'az vm start/deallocate' for Azure, 'aws ec2 start/stop-instances' for AWS.
    """

    # Load credentials/environment
    load_environment(customer, environment, provider)

    terraform_dir = os.path.join("deployments", customer, environment, "terraform")
    if not os.path.exists(terraform_dir):
        click.echo(f"Terraform directory {terraform_dir} does not exist.")
        sys.exit(1)

    output_file = os.path.join(terraform_dir, "tf_outputs.json")
    try:
        subprocess.run(["terraform", "output", "-json"], cwd=terraform_dir, check=True, stdout=open(output_file, "w"))
    except subprocess.CalledProcessError as e:
        click.echo(f"Failed to get terraform outputs: {e}")
        sys.exit(1)

    try:
        with open(output_file, "r") as f:
            outputs = json.load(f)
    except Exception as e:
        click.echo(f"Failed to load terraform outputs: {e}")
        sys.exit(1)

    if provider == "azure":
        ensure_az_logged_in(customer, environment, provider)
        vm_names = outputs.get("vm_names", {}).get("value", [])
        if not vm_names:
            click.echo("No VM names found in terraform outputs under 'vm_names'.")
            sys.exit(1)
        resource_group = outputs.get("resource_group_name", {}).get("value")
        if not resource_group:
            click.echo("No resource group name found in terraform outputs under 'resource_group_name'.")
            sys.exit(1)
        for vm in vm_names:
            if action == "up":
                cmd = ["az", "vm", "start", "--resource-group", resource_group, "--name", vm]
            elif action == "down":
                cmd = ["az", "vm", "deallocate", "--resource-group", resource_group, "--name", vm]
            else:
                click.echo(f"Unknown VM power action: {action}")
                sys.exit(1)
            cmd_str = " ".join(cmd)
            print(f"Executing: {cmd_str}")
            try:
                subprocess.run(cmd, check=True)
            except subprocess.CalledProcessError as e:
                click.echo(f"Failed to {action} VM '{vm}': {e}")

    elif provider == "aws":
        instance_ids = outputs.get("vm_instance_ids", {}).get("value", [])
        if not instance_ids:
            click.echo("No instance IDs found in terraform outputs under 'vm_instance_ids'.")
            sys.exit(1)
        for instance_id in instance_ids:
            if action == "up":
                cmd = ["aws", "ec2", "start-instances", "--instance-ids", instance_id]
            elif action == "down":
                cmd = ["aws", "ec2", "stop-instances", "--instance-ids", instance_id]
            else:
                click.echo(f"Unknown VM power action: {action}")
                sys.exit(1)
            cmd_str = " ".join(cmd)
            print(f"Executing: {cmd_str}")
            try:
                subprocess.run(cmd, check=True)
            except subprocess.CalledProcessError as e:
                click.echo(f"Failed to {action} instance '{instance_id}': {e}")

    else:
        click.echo(f"Provider '{provider}' not supported for VM power operations.")
        sys.exit(1)

def bash_source(envfile: str):

    """ this function runs a 'source' on the dotenv file, and loads
    its content in os.environment

    :param envfile: str, the path of the dotenv file to 'source'
    """

    print(f"Executing a source on dotenv file {envfile}")

    if os.path.isfile(envfile):
        print("File exists")
        command = format('env -i bash -c "source \'%s\' && env"' % envfile)
        for line in subprocess.getoutput(command).split("\n"):
            # print(line)
            if "=" in line:
                key, value = line.split("=", 1)
                os.environ[key] = value

def remove_known_host(ip_address):
    known_hosts_path = os.path.expanduser("~/.ssh/known_hosts")

    # Call ssh-keygen to remove all matching entries
    try:
        cmd_list = ["ssh-keygen", "-f", known_hosts_path, "-R", ip_address]
        cmd_string = " ".join(cmd_list)
        print(f"Executing command :\n{cmd_string}")
        subprocess.run(
            cmd_list,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        print(f"✅ Removed entries for {ip_address} from known_hosts.")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error removing {ip_address}: {e.stderr.decode().strip()}", file=sys.stderr)
        sys.exit(1)

def load_environment(customer, environment, provider=None, ansible=False):
    """Load all necessary environment files"""

    # Load provider credentials
    if provider is not None:
        bash_source(os.path.join("credentials", provider, ".env"))
        # bash_source(os.path.join("..", "..", "..", "..", "credentials", provider, ".env"))

    # print(os.getenv("TF_VAR_client_id"))
    # sys.exit()

    # Load current customer common stack credentials
    stack_common_env_file = os.path.join("credentials", customer, "all_environments", "common", ".env")
    if os.path.isfile(stack_common_env_file):
        load_dotenv(stack_common_env_file)
    stack_current_env_file = os.path.join("credentials", customer, environment, "common", ".env")
    if os.path.isfile(stack_current_env_file):
        load_dotenv(stack_current_env_file)

    # Load current customer apps' credentials
    if ansible:
        for app in APPS:
            stack_app_env_file = os.path.join("credentials", customer, "all_environments", app, ".env")
            if os.path.isfile(stack_app_env_file):
                load_dotenv(stack_app_env_file)
        for app in APPS:
            stack_app_env_file = os.path.join("credentials", customer, environment, app, ".env")
            if os.path.isfile(stack_app_env_file):
                load_dotenv(stack_app_env_file)

def merge_dicts(base, override):
    """Recursively merge two dictionaries, giving priority to 'override'."""
    result = base.copy()
    for key, value in override.items():
        if (
            key in result
            and isinstance(result[key], dict)
            and isinstance(value, dict)
        ):
            result[key] = merge_dicts(result[key], value)
        else:
            result[key] = value
    return result

def update_yaml_with_dict(input_file, override_dict):
    with open(input_file, 'r') as f:
        base_yaml = yaml.safe_load(f) or {}

    merged = merge_dicts(base_yaml, override_dict)

    with open(input_file, 'w') as f:
        yaml.dump(merged, f, default_flow_style=False)


def load_deployments_config():
    """Load deployments.yml configuration file."""
    config_file = os.path.join("deployments", "deployments.yml")
    if os.path.exists(config_file):
        with open(config_file, "r") as f:
            return yaml.safe_load(f) 
    return {}

def set_deployments_config(deployments, customer, environment):
    """ Insert customer and environment inside deployments.yml """
    if customer not in deployments["customers"].keys():
        deployments["customers"][customer] = {
            "provider": "aws",
            "environments": [environment]
        }
    if environment not in deployments["customers"][customer]["environments"]:
        deployments["customers"][customer]["environments"].append(environment)
    
    config_file = os.path.join("deployments", "deployments.yml")
    with open(config_file, "w") as f:
        yaml.dump(deployments, f)


def prompt_for_customer():
    """Prompt the user to choose an existing provider (customer) or create a new one."""
    deployments = load_deployments_config()
    customers = list(deployments.get("customers", {}).keys())
    choices = customers + ["Create new provider"]
    questions = [
        {
            "type": "list",
            "name": "customer",
            "message": "Choose a provider (customer):",
            "choices": choices,
        }
    ]
    answer = prompt(questions)
    if answer["customer"] == "Create new provider":
        new_question = [
            {
                "type": "input",
                "name": "customer",
                "message": "Enter new provider (customer) name:",
            }
        ]
        answer = prompt(new_question)
    return answer["customer"]


def prompt_for_environment(customer):
    """Prompt the user to choose an existing environment for the given customer or create one."""
    deployments = load_deployments_config()
    customer_data = deployments.get("customers", {}).get(customer, {})
    envs = customer_data.get("environments", [])
    choices = envs + ["Create new environment"]
    questions = [
        {
            "type": "list",
            "name": "environment",
            "message": f"Choose an environment for {customer}:",
            "choices": choices,
        }
    ]
    answer = prompt(questions)
    if answer["environment"] == "Create new environment":
        new_question = [
            {
                "type": "input",
                "name": "environment",
                "message": "Enter new environment name:",
            }
        ]
        answer = prompt(new_question)
    return answer["environment"]


def prompt_for_command():
    """Prompt the user to select one of the allowed command values."""
    questions = [
        {
            "type": "list",
            "name": "command",
            "message": "Choose a command:",
            "choices": ALLOWED_COMMANDS,
        }
    ]
    answer = prompt(questions)
    return answer["command"]


@click.command()
@click.argument("customer", required=False)
@click.argument("environment", required=False)
@click.argument("command", required=False)
@click.argument("app", required=False)
@click.argument("branch", required=False)
@click.option('--restricted-vms', '-r',
              default=None,
              help="restrict ansible command to hosts listed")
def cli(customer, environment, command, app, branch, restricted_vms):
    """
    CLI script to manage deployments.

    Depending on the number of provided arguments, the script will either use
    the passed CUSTOMER, ENVIRONMENT, and COMMAND or prompt you to select/create them.
    """

    # We load current deployments
    deployments = load_deployments_config()

    # No arguments provided: prompt for provider and environment then command.
    if not customer:
        customer = prompt_for_customer()
        environment = prompt_for_environment(customer)
        command = prompt_for_command()

    # One argument (assumed to be CUSTOMER): validate and prompt for environment and command.
    elif customer and not environment and not command:
        
        if customer not in deployments.get("customers", {}):
            click.echo(
                f"Provider (customer) '{customer}' not found in deployments.yml. Creating new entry."
            )
            # Depending on your use case you might update deployments.yml here.
        environment = prompt_for_environment(customer)
        command = prompt_for_command()

    # Two arguments provided: prompt for command.
    elif customer and environment and not command:
        command = prompt_for_command()

    # Verify that COMMAND is among allowed values.
    if command not in ALLOWED_COMMANDS:
        click.echo(
            f"Invalid command: {command}. Allowed commands are: {', '.join(ALLOWED_COMMANDS)}"
        )
        sys.exit(1)

    # Ensure that customer and environment are set inside deployments.yml
    set_deployments_config(deployments, customer, environment)

    # Get cloud provider
    provider = deployments["customers"][customer]["provider"]

    # Dispatch to the proper handler according to the command.
    if command == "init":
        handle_init(customer, environment, provider)
    elif command == "tf_init":
        handle_tf_init(customer, environment, provider)
    elif command == "tf_apply":
        handle_tf_apply(customer, environment, provider)
    elif command == "tf_destroy":
        handle_tf_destroy(customer, environment, provider)
    elif command == "config":
        handle_config(customer, environment)
    elif command in ["up", "down"]:   # <-- AJOUT
        handle_vm_power(customer, environment, provider, command)
    elif command in ANSIBLE_PLAYBOOKS:
        handle_ansible_command(customer, environment, provider, command, app, branch, restricted_vms)
    else:
        click.echo(f"Command '{command}' is not implemented")
        sys.exit(1)


def handle_init(customer, environment, provider):
    """Handles the 'init' command:
      - Creates necessary folders,
      - Copies the entire 'terraform' folder,
      - Instantiates Jinja templates for terraform.tfvars and input.yml.
    """
    base_path = os.path.join("deployments", customer, environment)
    terraform_path = os.path.join(base_path, "terraform")
    config_path = os.path.join(base_path, "config")

    os.makedirs(terraform_path, exist_ok=True)
    os.makedirs(config_path, exist_ok=True)

    if environment in CUSTOM_ENVIRONMENTS:
        src_terraform = os.path.join("infra_templates", provider, environment)
    else:
        src_terraform = os.path.join("infra_templates", provider,  "stack")

    if os.path.exists(src_terraform):
        # Copy all files and folders from the source terraform folder.
        for item in os.listdir(src_terraform):
            
            s = os.path.join(src_terraform, item)
            d = os.path.join(terraform_path, item)
            if os.path.isdir(s):
                continue
                if os.path.exists(d):
                    shutil.rmtree(d)
                shutil.copytree(s, d)
            else:
                filetype = item.split('.')
                if len(filetype) > 1:
                    filetype = filetype[1]
                else:
                    filetype = None
                if filetype == "tf":
                    shutil.copy2(s, d)
    else:
        click.echo("Source terraform directory not found.")
        sys.exit(1)

    # Create a Jinja2 environment assuming templates are in the current directory.
    jinja_env = Environment(loader=FileSystemLoader("."))

    # Render terraform.tfvars.j2
    override = {}
    deployments_file = os.path.join("deployments", "deployments.yml")
    with open(deployments_file, "r") as fp:
        override = yaml.load(fp, Loader=yaml.FullLoader)
        override = override["customers"].get(customer, {""}).get("customize", {}).get(environment, {})

    terraform_template_path = os.path.join(src_terraform, "terraform.tfvars.j2")
    if os.path.exists(terraform_template_path):
        template = jinja_env.get_template(terraform_template_path)
        rendered = template.render(customer=customer, environment=environment, **override)
        output_tfvars = os.path.join(terraform_path, "terraform.tfvars")
        with open(output_tfvars, "w") as f:
            f.write(rendered)
    else:
        click.echo(f"Template {terraform_template_path} not found.")

    # Render config/input.yml.j2
    config_template_path = os.path.join("config", "input.yml.j2")
    if os.path.exists(config_template_path):
        template = jinja_env.get_template(config_template_path)
        rendered = template.render(customer=customer, environment=environment, vm_username=PROVIDER_USERNAME[provider])
        output_input = os.path.join(config_path, "input.yml")
        with open(output_input, "w") as f:
            f.write(rendered)
    else:
        click.echo(f"Template {config_template_path} not found.")

    click.echo("Initialization completed.")


def handle_tf_init(customer, environment, provider):
    """Handles the 'tf_init' command:
      - Sources credentials/.env,
      - Calls 'terraform init' interactively in the target directory.
    """

    load_environment(customer, environment, provider)
    
    terraform_dir = os.path.join("deployments", customer, environment, "terraform")
    if not os.path.exists(terraform_dir):
        click.echo(f"Terraform directory {terraform_dir} does not exist. Please run init first.")
        sys.exit(1)
    try:
        subprocess.run(["terraform", "init"], cwd=terraform_dir, check=True)
    except subprocess.CalledProcessError as e:
        click.echo(f"Terraform init failed: {e}")


def handle_tf_apply(customer, environment, provider):
    """Handles the 'tf_apply' command:
      - Sources credentials/.env,
      - Calls 'terraform apply' interactively in the target directory.
    """

    load_environment(customer, environment, provider)
    
    terraform_dir = os.path.join("deployments", customer, environment, "terraform")
    if not os.path.exists(terraform_dir):
        click.echo(f"Terraform directory {terraform_dir} does not exist. Please run init first.")
        sys.exit(1)
    try:
        subprocess.run(["terraform", "apply"], cwd=terraform_dir, check=True)
    except subprocess.CalledProcessError as e:
        click.echo(f"Terraform apply failed: {e}")


def handle_tf_destroy(customer, environment, provider):
    """Handles the 'tf_destroy' command:
      - Sources credentials/.env,
      - Calls 'terraform destroy' interactively in the target directory.
    """

    load_environment(customer, environment, provider)

    terraform_dir = os.path.join("deployments", customer, environment, "terraform")
    if not os.path.exists(terraform_dir):
        click.echo(f"Terraform directory {terraform_dir} does not exist. Please run init first.")
        sys.exit(1)
    try:
        subprocess.run(["terraform", "destroy"], cwd=terraform_dir, check=True)
    except subprocess.CalledProcessError as e:
        click.echo(f"Terraform apply failed: {e}")


def handle_config(customer, environment):
    """Handles the 'config' command:
      - Sources credentials/.env,
      - Runs 'terraform output -json' and stores output,
      - Uses the output to instantiate several Jinja templates,
      - Writes rendered templates to the config folder.
    """

    load_environment(customer, environment, ansible=True)

    terraform_dir = os.path.join("deployments", customer, environment, "terraform")
    config_dir = os.path.join("deployments", customer, environment, "config")

    output_file = os.path.join(terraform_dir, "tf_outputs.json")
    try:
        with open(output_file, "w") as f:
            subprocess.run(["terraform", "output", "-json"], cwd=terraform_dir, check=True, stdout=f)
    except subprocess.CalledProcessError as e:
        click.echo(f"Terraform output failed: {e}")
        sys.exit(1)

    try:
        with open(output_file, "r") as f:
            tf_outputs = json.load(f)
    except Exception as e:
        click.echo(f"Failed to load terraform outputs: {e}")
        sys.exit(1)

    jinja_env = Environment(loader=FileSystemLoader("."))

    # Get template_data.json
    if environment not in CUSTOM_ENVIRONMENTS:
        tpl = "template_data.json.j2"
    else:
        tpl = f"template_data_{environment}.json.j2"
    tpl_path = os.path.join("config", tpl)
    template = jinja_env.get_template(tpl_path)
    rendered = template.render(customer=customer, environment=environment, tf_outputs=tf_outputs)
    template_data_file_path = os.path.join(config_dir, "template_data.json")
    with open(template_data_file_path, "w") as f:
        f.write(rendered)

    with open(template_data_file_path, "r") as f:
        template_data = json.load(f)

    # Define template mapping: source template -> destination file
    templates = {
        "ansible.cfg": "ansible.cfg",
        "input.yml.j2": "input.yml",
    }
    if environment not in CUSTOM_ENVIRONMENTS:
        # templates["template_data.json.j2"] = "template_data.json"
        templates["hosts.yml.j2"] = "hosts.yml"
        templates["ssh.cfg.j2"] = "ssh.cfg"
    else:
        # templates[f"template_data_{environment}.json.j2"] = "template_data.json"
        templates[f"hosts_{environment}.yml.j2"] = "hosts.yml"
        templates[f"ssh_{environment}.cfg.j2"] = "ssh.cfg"
    
    template_data["customer"] = customer
    template_data["environment"] = environment
    template_data["home"] = os.path.expanduser("~")

    for tpl, out in templates.items():
        tpl_path = os.path.join("config", tpl)
        if os.path.exists(tpl_path):
            template = jinja_env.get_template(tpl_path)
            rendered = template.render(template_data)
            output_file_path = os.path.join(config_dir, out)
            with open(output_file_path, "w") as f:
                f.write(rendered)
        else:
            click.echo(f"Template {tpl_path} not found.")

    # Set the input.yml file
    input_file = os.path.join(config_dir, "input.yml")
    override = {}
    deployments_file = os.path.join("deployments", "deployments.yml")
    with open(deployments_file, "r") as fp:
        override = yaml.load(fp, Loader=yaml.FullLoader)
        override = override["customers"].get(customer, {""}).get("customize", {}).get(environment, {})

    update_yaml_with_dict(input_file, override)

    click.echo("Configuration generation completed.")


def handle_ansible_command(customer, environment, provider, command, app, branch, restricted_vms):
    """
    Handles the ansible-related commands ("rails", "setup", "lb", "deploy", "update", "sql", "check"):
      - Sources credentials/.env,
      - If command is 'setup', initializes test SSH connections,
      - Executes ansible-playbook using input and template_data files,
      - The playbook is chosen from a mapping.
    """

    load_environment(customer, environment, provider=provider, ansible=True)

    # For 'proxy' and 'route' commands, the real environment is 'common'
    if command in ["ssl", "route"]:
        # target_customer = customer
        target_environment = environment
        # customer = "internal"
        environment = "common"

    config_dir = os.path.join("deployments", customer, environment, "config")

    # For 'setup', test SSH connectivity based on the SSH configuration.
    if command == "setup":
        ssh_cfg_file = os.path.join(config_dir, "ssh.cfg")
        if os.path.exists(ssh_cfg_file):
            with open(ssh_cfg_file, "r") as f:
                # Assuming each line contains a host name or connection string.
                hosts = [line.strip().split(' ')[1] for line in f if line.startswith("Host")]
            with open(ssh_cfg_file, "r") as f:
                addresses = [line.strip().split(' ')[1] for line in f if line.startswith("  HostName")]
                print(addresses)
                
            for index, host in enumerate(hosts):
                click.echo(f"Testing SSH connection for host: {host}")
                remove_known_host(addresses[index])
                # A basic test (for example purposes) could be:
                try:
                    ssh_cmd = [
                            "ssh", "-F", "ssh.cfg",
                            "-o", "BatchMode=yes",
                            # "-o", "StrictHostKeyChecking=accept-new",
                            # "-o", "CanonicalizeHostname=no",
                            host, "exit"
                        ]
                    ssh_string = " ".join(ssh_cmd)
                    # print(f"Executing command :\n{ssh_string}\nin folder {config_dir}")
                    subprocess.run(
                        ssh_cmd,
                        cwd=config_dir,
                        check=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )
                    click.echo(f"SSH connection to {host} successful.")
                except subprocess.CalledProcessError:
                    click.echo(f"SSH connection to {host} failed.")
        else:
            click.echo(f"SSH configuration file {ssh_cfg_file} not found.")

    # Get the target playbook for the given command.
    playbook = ANSIBLE_PLAYBOOKS.get(command)
    if not playbook:
        click.echo(f"No playbook mapped for command: {command}")
        sys.exit(1)

    # input_file = os.path.join(config_dir, "input.yml")
    # extra_vars_file = os.path.join(config_dir, "template_data.json")
    # playbook_path = os.path.join(os.getcwd(), "config", playbook)

    input_file = "hosts.yml"
    extra_vars_file = "template_data.json"
    if command in ["ssl", "route"]:
        extra_vars_file = os.path.join("..", "..", "..", customer, target_environment, "config", extra_vars_file)
    extra_vars_file_2 = "input.yml"
    playbook_path = os.path.join("..", "..", "..", "..", "config", "ansible_playbooks", playbook)

    if playbook in PROVIDER_SPECIFIC:
        playbook_path = playbook_path.replace(".yml", f"_{provider}.yml")

    if not os.path.exists(os.path.join(config_dir, playbook_path)):
        click.echo(f"Playbook {playbook} not found.")
        sys.exit(1)

    ansible_cmd = [
        "ansible-playbook",
        "-i",
        input_file,
        "-e",
        f"@{extra_vars_file}",
        "-e",
        f"@{extra_vars_file_2}"
    ]

    if command == "update":
        if app is not None:
            if branch is not None:
                ansible_cmd += ["-e", "\"git_branch={" + app + ": \"" +  branch + "\" }\"", "--limit", app]

    if restricted_vms is not None:
        if isinstance(restricted_vms, str):
            ansible_cmd += ["-l", restricted_vms]

    ansible_cmd.append(playbook_path)

    cmd_string = " ".join(ansible_cmd)
    print(f"Running command :\n{cmd_string}\nin folder {config_dir}")

    # Prepare env: copy current env + set ANSIBLE_CONFIG
    env = os.environ.copy()
    env["ANSIBLE_CONFIG"] = "ansible.cfg"

    try:
        subprocess.run(ansible_cmd, cwd=config_dir, env=env, check=True)
    except subprocess.CalledProcessError as e:
        click.echo(f"Ansible playbook execution failed: {e}")


if __name__ == "__main__":
    cli()
