resource "aws_vpc" "sd_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "sd-forge-vpc"
  }
}

resource "aws_subnet" "sd_public_subnet" {
  for_each = {
    a = "10.0.1.0/24"
    b = "10.0.2.0/24"
    c = "10.0.3.0/24"
  }

  vpc_id                  = aws_vpc.sd_vpc.id
  cidr_block              = each.value
  availability_zone       = "${var.aws_region}${each.key}"
  map_public_ip_on_launch = true

  tags = {
    Name = "sd-forge-public-subnet-${each.key}"
  }
}

resource "aws_internet_gateway" "sd_igw" {
  vpc_id = aws_vpc.sd_vpc.id

  tags = {
    Name = "sd-forge-igw"
  }
}

resource "aws_route_table" "sd_public_rt" {
  vpc_id = aws_vpc.sd_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sd_igw.id
  }

  tags = {
    Name = "sd-forge-public-rt"
  }
}

resource "aws_route_table_association" "sd_public_assoc" {
  for_each       = aws_subnet.sd_public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.sd_public_rt.id
}
