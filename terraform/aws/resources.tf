resource "aws_vpc" "manuka" {
  cidr_block           = var.VPC_CIDRBlock
  instance_tenancy     = var.VPC_InstanceTenancy
  enable_dns_support   = var.VPC_DNSSupport 
  enable_dns_hostnames = var.VPC_DNSHostNames
  
  tags = {
    Name = "Manuka VPC"
    }
}

resource "aws_subnet" "manuka" {
  vpc_id                  = aws_vpc.manuka.id
  cidr_block              = var.VPC_SubnetCIDRBlock
  map_public_ip_on_launch = var.VPC_MapPublicIP

  tags = {
    Name = "Manuka Subnet"
  }
}

resource "aws_route_table" "manuka" {
  vpc_id = aws_vpc.manuka.id

  tags = {
    Name = "Manuka Route Table"
  }
}

resource "aws_route_table_association" "manuka" {
  subnet_id      = aws_subnet.manuka.id
  route_table_id = aws_route_table.manuka.id
}

resource "aws_internet_gateway" "manuka" {
  vpc_id = aws_vpc.manuka.id

  tags = {
    Name = "Manuka Internet Gateway"
  }
}

resource "aws_route" "manuka" {
  route_table_id         = aws_route_table.manuka.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.manuka.id
}

resource "aws_network_acl" "manuka" {
  vpc_id = aws_vpc.manuka.id
  subnet_ids = [ aws_subnet.manuka.id ]
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }
  
  tags = {
    Name = "Manuka Network ACL"
  }
}

resource "aws_security_group" "manuka" {
  name        = "Manuka"
  description = "Manuka Security Group"
  vpc_id      = aws_vpc.manuka.id

  ingress {
    description = "Cowrie - SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Cowrie - Telnet"
    from_port   = 23
    to_port     = 23
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Web - HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    description = "Web - HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    description = "Admin - SSH"
    from_port   = 50220
    to_port     = 50220
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Manuka Security Group"
  }
}

resource "aws_key_pair" "manuka" {
  key_name   = var.EC2_SSH_Key_Name
  public_key = tls_private_key.manuka.public_key_openssh
}

resource "aws_instance" "manuka" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.EC2_Instance_Type
  key_name                    = aws_key_pair.manuka.key_name
  subnet_id                   = aws_subnet.manuka.id
  vpc_security_group_ids      = [aws_security_group.manuka.id]
  user_data_base64            = data.template_cloudinit_config.config.rendered
  associate_public_ip_address = true
  
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    Name = "Manuka"
  }
}