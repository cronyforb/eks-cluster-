# Minimal VPC for EKS
resource "aws_vpc" "louis_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "louis-vpc"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.louis_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "louis-private-1a"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.louis_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "louis-private-1b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.louis_vpc.id
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.private_1.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.louis_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}
