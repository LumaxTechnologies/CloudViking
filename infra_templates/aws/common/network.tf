###############################################################################
# VPC & SUBNETS
###############################################################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-main-vpc", var.customer)
    }
  )
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-public-subnet", var.customer)
    }
  )
}

###############################################################################
# INTERNET GATEWAY & ROUTING (PUBLIC)
###############################################################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-internet-gateway", var.customer)
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-public-rt", var.customer)
    }
  )
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}
############
# elastic IP for the NAT Gateway
############

resource "aws_eip" "elastic_ip" {

  depends_on = [aws_internet_gateway.igw]

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-elastic-ip", var.customer)
    }
  )
}

############
# NAT Gateway
# allows communication from subnets to Internet egress only (for private subnets)
# used with an elastic IP
# The NAT Gateway allows all private VMs (i.e. without a public IP) to reach Internet, with the same IP (the one from the NAT Gateway)
############

resource "aws_nat_gateway" "nat_gateway" {

  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-nat-gateway", var.customer)
    }
  )

}
