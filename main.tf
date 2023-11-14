# main.tf

provider "aws" {
  region = "eu-central-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block          = var.cidr
  enable_dns_support  = true
  enable_dns_hostnames = true
  instance_tenancy    = "default"

  tags = {
    Name        = "MainVPC"
    Environment = var.environment
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.publicCIDR[0]
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "PublicSubnet"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "MainInternetGateway"
    Environment = var.environment
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "PublicRouteTable"
    Environment = var.environment
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# EC2 Instance
resource "aws_instance" "ec2" {
  ami             = var.instance_AMI
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.public.id
  key_name        = "terraform" 
  vpc_security_group_ids = ["sg-090bb533ddcb4abf0"] 
  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name        = "EC2Instance"
    Environment = var.environment
  }
}

# Security Group
resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name        = "MainSecurityGroup"
    Environment = var.environment
  }
}
