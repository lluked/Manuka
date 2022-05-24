resource "aws_vpc" "manuka" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = var.vpc_instance_tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Manuka VPC"
    }
}

resource "aws_subnet" "manuka" {
  vpc_id                  = aws_vpc.manuka.id
  cidr_block              = var.subnet_cidr_block
  map_public_ip_on_launch = true

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
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }
  
  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
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
    from_port   = var.cowrie_ssh_port
    to_port     = var.cowrie_ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Cowrie - Telnet"
    from_port   = var.cowrie_telnet_port
    to_port     = var.cowrie_telnet_port
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
    from_port   = var.ssh_port
    to_port     = var.ssh_port
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
  key_name   = "Manuka"
  public_key = tls_private_key.manuka.public_key_openssh
}

resource "aws_instance" "manuka" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_instance_type
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

  # remote-exec to delay local-exec until instance is ready
  provisioner "remote-exec" {
    inline = ["echo remote-exec > terraform.txt"]
    connection {
      host        = aws_instance.manuka.public_ip
      type        = "ssh"
      user        = var.vm_user
      private_key = tls_private_key.manuka.private_key_pem
    }
  }

  # Provision Ansible Playbooks
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.vm_user} -i '${aws_instance.manuka.public_ip},' --private-key ./keys/private.pem --extra-vars 'traefik_kibana_proxy_password=${var.traefik_kibana_proxy_password} elastic_password=${var.elastic_password} logstash_system_password=${var.logstash_system_password} logstash_internal_password=${var.logstash_internal_password} kibana_system_password=${var.kibana_system_password} cowrie_ssh_port=${var.cowrie_ssh_port} cowrie_telnet_port=${var.cowrie_telnet_port} ssh_port=${var.ssh_port}' ../../ansible/main.yml"
  }

  # Restart instance after provisioning
  provisioner "local-exec" {
    command = "ssh -tt -o StrictHostKeyChecking=no ${var.vm_user}@${aws_instance.manuka.public_ip} -i ./keys/private.pem sudo 'shutdown -r'"
  }

  tags = {
    Name = "Manuka"
  }
}
