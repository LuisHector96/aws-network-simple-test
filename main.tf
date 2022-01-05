# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.5.0.0/16"

  tags = {
    Name = "amat-test-vpc-tf"
  }
}

# Subnet connected to previous VPC
resource "aws_subnet" "my_public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.5.3.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "amat-test-subnet-tf"
  }
}

# Subnet connected to previous VPC
resource "aws_subnet" "my_private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.5.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "amat-test-subnet-tf"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "amat-test-igw"
  }
}

# Elastic IP
resource "aws_eip" "my_eip" {
  vpc = true

  depends_on                = [aws_internet_gateway.my_igw]

  tags = {
    Name = "amat-test-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "my_nat_gw" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.my_public_subnet.id

  tags = {
    Name = "amat-test-nat-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.my_igw]
}

# Public route table
resource "aws_route_table" "my_public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "amat-test-route-table-public"
  }
}

# Private route table
resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my_nat_gw.id
  }

  tags = {
    Name = "amat-test-route-table-private"
  }
}

resource "aws_security_group" "dynamic-sg" {
  name        = "amat-test-sg-dynamic"
  description = "Ingress for Vault"
  vpc_id      = aws_vpc.my_vpc.id

  dynamic "ingress" {
    for_each = var.sg_ports
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "egress" {
    for_each = var.sg_ports
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
