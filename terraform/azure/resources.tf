# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "Manuka-RG"
  location = var.region
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "Manuka-VNet"
    address_space       = ["10.0.0.0/16"]
    location            = var.region
    resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public ip
resource "azurerm_public_ip" "publicip" {
  name                = "Manuka-IP"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create network security group and rules
resource "azurerm_network_security_group" "nsg" {
  name                = "Manuka-NSG"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Admin-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "50220"
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
    destination_port_range     = "22"
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
    destination_port_range     = "23"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                      = "Manuka-NIC"
  location                  = var.region
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "manuka-IPConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Associate network security group with network interface
resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create ssh key
resource "azurerm_ssh_public_key" "manuka" {
  name                = "Manuka-PublicKey"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  public_key          = tls_private_key.manuka.public_key_openssh
}

# Create linux virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "Manuka-VM"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.region
  size               = "Standard_DS1_v2"
  admin_username = var.vmUser
  network_interface_ids = [azurerm_network_interface.nic.id]
  custom_data = data.template_cloudinit_config.config.rendered

  admin_ssh_key {
    username   = var.vmUser
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

}