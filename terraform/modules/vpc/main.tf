resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name        = "${var.environment}-vpc-${var.region_name}"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  for_each                = var.public_subnet_cidrs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.environment}-public-subnet-${each.key}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  for_each                = var.private_subnet_cidrs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  
  tags = {
    Name        = "${var.environment}-private-subnet-${each.key}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "${var.environment}-igw-${var.region_name}"
    Environment = var.environment
  }
}

resource "aws_eip" "nat" {
  for_each = var.public_subnet_cidrs
  domain = "vpc"
  
  tags = {
    Name        = "${var.environment}-nat-eip-${each.key}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "nat" {
  for_each      = var.public_subnet_cidrs
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  
  tags = {
    Name        = "${var.environment}-nat-gateway-${each.key}"
    Environment = var.environment
  }
  
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name        = "${var.environment}-public-route-table-${var.region_name}"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  for_each = var.private_subnet_cidrs
  vpc_id   = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
  
  tags = {
    Name        = "${var.environment}-private-route-table-${each.key}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnet_cidrs
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnet_cidrs
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}