output "instance_ip" {
  description = "The public ip for ssh access"
  value = data.azurerm_public_ip.ip.ip_address
}

output "kibana" {
  description = "kibana access"
  value       = "${data.azurerm_public_ip.ip.ip_address}/xyz"
}

output "traefik" {
  description = "traefik access"
  value       = "${data.azurerm_public_ip.ip.ip_address}/dashboard/"
}

output "ssh_port" {
  value = "50220"
}

output "ssh_user" {
  value = var.vmUser
}

output "ssh_private_key" {
  value = "./keys/private.pem"
}