resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  count = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  count = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  count = length(aws_subnet.public_subnets)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat_eip" {
  count = length(var.availability_zones)
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  count = length(var.availability_zones)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = "nat-gateway-${count.index}"
  }
}

resource "aws_route_table" "private_rt" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  count = length(var.availability_zones)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private_rt[count.index].id
}