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

# Proxy Host in Public Subnet
resource "aws_instance" "proxy" {
  ami               = data.aws_ami.amazon_linux.id
  instance_type     = var.proxy_type
  subnet_id         = aws_subnet.public_subnet.id
  key_name          = aws_key_pair.public_key_import["proxy"].key_name
  vpc_security_group_ids   = [aws_security_group.proxy_sg.id]
  associate_public_ip_address = true

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-proxy", var.customer, var.environment)
    },
    {
      Type = "proxy"
    }
  )

  depends_on = [ 
    aws_key_pair.public_key_import
  ]
  
  lifecycle {
      ignore_changes = [ami]
    }
}

# # Jumpbox in Private Subnet
# resource "aws_instance" "jumpbox" {
#   ami             = data.aws_ami.amazon_linux.id
#   instance_type   = var.jumpbox_type
#   subnet_id       = aws_subnet.private_subnet_1.id
#   key_name        = aws_key_pair.public_key_import["jumpbox"].key_name
#   vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]

#   iam_instance_profile   = aws_iam_instance_profile.ec2_profile[var.jumpbox_instance_profile].name

#   tags = merge(
#     local.common_labels,
#     {
#       Name = "jumpbox"
#     }
#   )

#   depends_on = [ 
#     aws_key_pair.public_key_import
#   ]
# }

# # Medium EC2 Instances in Private Subnet (for_each over input list)
# resource "aws_instance" "medium_ec2" {
#   for_each = { for ec2 in var.medium_ec2s : ec2.name => ec2 }

#   ami             = data.aws_ami.amazon_linux.id
#   instance_type   = each.value.instance_type
#   subnet_id       = aws_subnet.private_subnet_1.id
#   key_name        = aws_key_pair.public_key_import["medium_ec2"].key_name
#   vpc_security_group_ids = [aws_security_group.ec2_sg.id]

#   iam_instance_profile = aws_iam_instance_profile.ec2_profile[each.value.instance_profile].name

#   root_block_device {
#     volume_size = each.value.volume_size       # Size in GB
#     volume_type = each.value.volume_type    # Optional: gp2, gp3, io1, etc.
#     delete_on_termination = true
#   }


#   tags = merge(
#     local.common_labels,
#     {
#       Name = each.value.name
#     }
#   )

#   depends_on = [ 
#     aws_key_pair.public_key_import
#   ]
# }

###############################################################################
# SECURITY GROUPS (Placeholders – modify ingress rules as needed)
###############################################################################
resource "aws_security_group" "proxy_sg" {
  name        = format("%s-%s", local.common_prefix_dash, "proxy-sg")
  description = "Security group for proxy host"
  vpc_id      = aws_vpc.main.id

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
    description = "Allow https from anywhere (adjust as needed)"
    from_port   = 443
    to_port     = 443
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

# resource "aws_security_group" "jumpbox_sg" {
#   name        = format("%s-%s", local.common_prefix_dash, "jumpbox-sg")
#   description = "Security group for jumpbox"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description     = "Allow SSH from Bastion"
#     from_port       = 22
#     to_port         = 22
#     protocol        = "tcp"
#     security_groups = [aws_security_group.bastion_sg.id]
#   }

#   egress {
#     description = "Allow all outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "ec2_sg" {
#   name        = format("%s-%s", local.common_prefix_dash, "vm-sg")
#   description = "Security group for medium EC2 instances"
#   vpc_id      = aws_vpc.main.id

#   # Example ingress rule – dynamically generate rules based on var.network_rules as needed.
#   ingress {
#     description = "Allow traffic based on network rules (customize)"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = [var.vpc_cidr]  # Fill in as required
#   }

#   egress {
#     description = "Allow all outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }