resource "aws_vpc" "foundry_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_subnet" "foundry_subnet" {
  vpc_id                  = aws_vpc.foundry_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_subnet" "foundry_subnetb" {
  vpc_id                  = aws_vpc.foundry_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_route_table" "foundry_route_table" {
  vpc_id = aws_vpc.foundry_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.foundry-igw.id
  }

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_route_table_association" "foundry-public-subnet" {
  subnet_id      = aws_subnet.foundry_subnet.id
  route_table_id = aws_route_table.foundry_route_table.id
}

resource "aws_internet_gateway" "foundry-igw" {
  vpc_id = aws_vpc.foundry_vpc.id

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_security_group" "foundry_allow_tls" {
  name        = "foundry_allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.foundry_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.MY_IP}/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    application = "FoundryVTT"
  }
}