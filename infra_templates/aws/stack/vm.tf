###############################################################################
# COMPUTE RESOURCES
###############################################################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion Host in Public Subnet
resource "aws_instance" "bastion" {
  ami               = data.aws_ami.amazon_linux.id
  instance_type     = var.bastion_type
  subnet_id         = data.aws_subnet.public_subnet.id
  key_name          = aws_key_pair.public_key_import["bastion"].key_name
  vpc_security_group_ids   = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-bastion", var.customer, var.environment)
    },
    {
      Type = "bastion"
    }
  )

  depends_on = [ 
    aws_key_pair.public_key_import
  ]
}

# Jumpbox in Private Subnet
resource "aws_instance" "jumpbox" {
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = var.jumpbox_type
  subnet_id       = aws_subnet.private_subnet_1.id
  key_name        = aws_key_pair.public_key_import["jumpbox"].key_name
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]

  iam_instance_profile   = aws_iam_instance_profile.ec2_profile[var.jumpbox_instance_profile].name

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-jumpbox", var.customer, var.environment)
    },
    {
      Type = "jumpbox"
    }
  )

  depends_on = [ 
    aws_key_pair.public_key_import
  ]
}

# Medium EC2 Instances in Private Subnet (for_each over input list)
resource "aws_instance" "backend" {
  for_each = { for vm in var.medium_vms : vm.name => vm }

  ami             = data.aws_ami.amazon_linux.id
  instance_type   = each.value.instance_type
  subnet_id       = aws_subnet.private_subnet_1.id
  key_name        = aws_key_pair.public_key_import["medium_vms"].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile[each.value.instance_profile].name

  root_block_device {
    volume_size = each.value.volume_size       # Size in GB
    volume_type = each.value.volume_type    # Optional: gp2, gp3, io1, etc.
    delete_on_termination = true
  }


  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-%s", var.customer, var.environment, each.value.name)
    },
    {
      Type = each.value.name
    }
  )

  depends_on = [ 
    aws_key_pair.public_key_import
  ]
}

###############################################################################
# SECURITY GROUPS (Placeholders – modify ingress rules as needed)
###############################################################################
resource "aws_security_group" "bastion_sg" {
  name        = format("%s-%s", local.common_prefix_dash, "bastion-sg")
  description = "Security group for bastion host"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Allow SSH from anywhere (adjust as needed)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow http from anywhere (adjust as needed)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow psql from anywhere (adjust as needed)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jumpbox_sg" {
  name        = format("%s-%s", local.common_prefix_dash, "jumpbox-sg")
  description = "Security group for jumpbox"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "Allow SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = format("%s-%s", local.common_prefix_dash, "vm-sg")
  description = "Security group for medium EC2 instances"
  vpc_id      = data.aws_vpc.main.id

  # Example ingress rule – dynamically generate rules based on var.network_rules as needed.
  ingress {
    description = "Allow traffic based on network rules (customize)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]  # Fill in as required
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}