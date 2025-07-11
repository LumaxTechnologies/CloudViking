###############################################################################
# VPC & SUBNETS
###############################################################################

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [format("%s-main-vpc", var.customer)]
    # values = ["devops-main-vpc"]
  }

  filter {
    name   = "tag:Customer"
    # values = ["internal"]
    values = [var.customer]
    # values = ["devops"]
  }
}

data "aws_subnet" "public_subnet" {
  filter {
    name   = "tag:Name"
    # values = ["devops-public-subnet"]
    values = [format("%s-public-subnet", var.customer)]
  }

  filter {
    name   = "tag:Customer"
    # values = ["internal"]
    values = [var.customer]
    # values = ["devops"]
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = data.aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  # No public IP assignment
  map_public_ip_on_launch = false

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-private-subnet-1", var.customer, var.environment)
    }
  )
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = data.aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  # No public IP assignment
  map_public_ip_on_launch = false

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-private-subnet-2", var.customer, var.environment)
    }
  )
}

data "aws_nat_gateway" "nat_gateway" {

  filter {
    name   = "tag:Name"
    values = [format("%s-nat-gateway", var.customer)]
  }

  filter {
    name   = "tag:Customer"
    # values = ["internal"]
    values = [var.customer]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

############
# Private route tables
# allow resources to reach other resources on networks
############

resource "aws_route_table" "private_route_table_1" {

  vpc_id = data.aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_rta_1" {

  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table" "private_route_table_2" {

  vpc_id = data.aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_rta_2" {

  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}