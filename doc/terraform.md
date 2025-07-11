# Terraform philosophy

### How Terraform works

Terraform is a standalone executable, that you execute on a folder containing files expected by Terraform.

All files with a `.tf` extension inside this folder will be automatically loaded by Terraform during execution.

All the code written in all the `.tf` files will be used by Terrafom at execution time. You can write your code in as many files as you want, there is not enforced structure.

Files with a `.tfvars` and `.tfvars.json` extension allow to define variables respectively in HCL and json format for the execution. A file named `terraform.tfvars` and all files with a `.auto.tfvars` or `.auto.tfvars.json` will be automatically loaded, otherwise you have to explicitely list the `.tfvars` files to load by the Terrafom CLI at execution.

#### Provider

Inside the `.tf` files, Terraform will be looking for a block like this :

```tf
terraform {
	required_providers {
		<CHOSEN_PROVIDER> = {
			...
		}
	}
}
```

that will specify your chosen cloud provider, and a block like this :

```tf
provider "<CHOSEN_PROVIDER>" {
	<PROVIDER_CREDENTIALS> = ...
}
```

that will specify the credentials to connect to the provider

#### Variables

Terraform uses two kinds of variables :

- "public" variables declared externally at execution
- "internal" variables

The "public" variables are simply named "variables", the "internal" variables are called "locals" by Terraform

To use a variable inside Terraform, you have to declare it like this :

```tf
variable "<VARIABLE_NAME>" {
	...
}
```

Then you refer to it like this : `var.<VARIABLE_NAME>`

The values of all variables must be set at execution time, either using `.tfvars` files, or directly in the arguments of the CLI. If no values are set, Terraform will look at the variable definition if a default value is set. If not, it will return an error

To use a local variable, you have to declare it like this :

```tf
locals  {
	"<VARIABLE_NAME>" = ...
}
```

Then you refer to it like this : `local.<VARIABLE_NAME>`

#### Data and resources

Terraform can either dump the content of existing cloud resources, or create them

To read content of existing resources, you use `data` blocks :

```tf
data DATA_TYPE DATA_NAME {

}
```

To create resources, you use `resource` blocks :

```tf
resource DATA_TYPE DATA_NAME {

}
```

#### Outputs

An "output" is a kind of variable that will be dumped by Terraform at the end of its execution. It is useful to pipe the results of Terraform with other actions.

You declare it like this :

```tf
output "<OUTPUT_NAME>" {
	...
}
```

Output content can refers to variables, locals, resources or data.

#### Modules

Modules are a way to make Terraform code reusable. A module is a separated folder, containing all the needed files by Terraform (i.e. variables, resources, data, etc.) at the exception of the provider field, and the `terraform {}` block.

It means that insides modules you have to declare input variables and outputs.

You can call a module inside your main Terraform folder like this :

```tf
module "MODULE_NAME" {
	source = "<PATH_TO_MODULE_FOLDER>
	MODULE_VARIABLE_ONE = MODULE_VARIABLE_ONE_VALUE
	...
}
```

All the variables of the module must have their values provided at execution time, either by setting them in the `module` block, or by using default values in the declaration of the variables in the module folder.

Then, you can get the values contained in the `outputs` of the module folder by calling `module.MODULE_NAME.OUTPUT_NAME` in the main Terraform folder.