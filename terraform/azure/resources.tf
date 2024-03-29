# Create resource group
resource "azurerm_resource_group" "manuka" {
  name     = "Manuka-RG"
  location = var.azure_region
}

# Create virtual network
resource "azurerm_virtual_network" "manuka" {
  name                = "Manuka-VNet"
  address_space       = ["${var.network_address_space}"]
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.manuka.name
}

# Create subnet
resource "azurerm_subnet" "manuka" {
  name                 = "Manuka-SNet"
  resource_group_name  = azurerm_resource_group.manuka.name
  virtual_network_name = azurerm_virtual_network.manuka.name
  address_prefixes     = ["${var.subnet_address_prefixes}"]
}

# Create public ip
resource "azurerm_public_ip" "manuka" {
  name                = "Manuka-PubIP"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.manuka.name
  allocation_method   = "Static"
}

# Create network security group and rules
resource "azurerm_network_security_group" "manuka" {
  name                = "Manuka-NSG"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.manuka.name

  security_rule {
    name                       = "Admin-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.ssh_port
    source_address_prefix      = "${chomp(data.http.myip.body)}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Web-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "${chomp(data.http.myip.body)}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Web-HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${chomp(data.http.myip.body)}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Cowrie-SSH"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.cowrie_ssh_port
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Cowrie-Telnet"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.cowrie_telnet_port
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "manuka" {
  name                      = "Manuka-NIC"
  location                  = var.azure_region
  resource_group_name       = azurerm_resource_group.manuka.name

  ip_configuration {
    name                          = "manuka-IPConfig"
    subnet_id                     = azurerm_subnet.manuka.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.manuka.id
  }
}

# Associate network security group with network interface
resource "azurerm_network_interface_security_group_association" "manuka" {
  network_interface_id      = azurerm_network_interface.manuka.id
  network_security_group_id = azurerm_network_security_group.manuka.id
}

# Create ssh key
resource "azurerm_ssh_public_key" "manuka" {
  name                = "Manuka-PublicKey"
  resource_group_name = azurerm_resource_group.manuka.name
  location            = var.azure_region
  public_key          = tls_private_key.manuka.public_key_openssh
}

# Create linux virtual machine
resource "azurerm_linux_virtual_machine" "manuka" {
  name                  = "Manuka-VM"
  resource_group_name   = azurerm_resource_group.manuka.name
  location              = var.azure_region
  size                  = "${var.machine_size}"
  admin_username        = var.vm_user
  network_interface_ids = [azurerm_network_interface.manuka.id]
  custom_data           = data.template_cloudinit_config.config.rendered

  admin_ssh_key {
    username   = var.vm_user
    public_key = azurerm_ssh_public_key.manuka.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  # remote-exec to delay local-exec until instance is ready
  provisioner "remote-exec" {
    inline = ["echo remote-exec > terraform.txt"]
    connection {
      host        = azurerm_linux_virtual_machine.manuka.public_ip_address
      type        = "ssh"
      user        = var.vm_user
      private_key = tls_private_key.manuka.private_key_pem
    }
  }

  # Provision Ansible Playbooks
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.vm_user} -i '${azurerm_linux_virtual_machine.manuka.public_ip_address},' --private-key ./keys/private.pem --extra-vars 'traefik_kibana_proxy_password=${var.traefik_kibana_proxy_password} elastic_password=${var.elastic_password} logstash_system_password=${var.logstash_system_password} logstash_internal_password=${var.logstash_internal_password} kibana_system_password=${var.kibana_system_password} cowrie_ssh_port=${var.cowrie_ssh_port} cowrie_telnet_port=${var.cowrie_telnet_port} ssh_port=${var.ssh_port}' ../../ansible/main.yml"
  }

  # Restart instance after provisioning
  provisioner "local-exec" {
    command = "ssh -tt -o StrictHostKeyChecking=no ${var.vm_user}@${azurerm_linux_virtual_machine.manuka.public_ip_address} -i ./keys/private.pem sudo 'shutdown -r'"
  }

}
