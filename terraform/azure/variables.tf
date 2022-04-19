# region
variable "azure_region" {
  default = "westus2"
}

# machine
variable "machine_size" {
  # Standard_DS1_v2 = 1 vCPU, 3.5 GiB RAM
  default = "Standard_DS1_v2"
}

# network
variable "network_address_space" {
  default = "10.0.0.0/16"
}

# subnet
variable "subnet_address_prefixes" {
  default = "10.0.2.0/24"
}

# vm user
variable "vm_user" {
  type = string
  default = "ubuntu"
}

# cloud-init
variable "timezone" {
  default = "UTC"
}

# traefik
variable "traefik_kibana_proxy_password" {
  type = string
  description = "Password to access kibana through traefik proxy"
}

# elastic
variable "elastic_password" {
  type = string
  description = "Elastic user password, used to access kibana"
}

variable "logstash_system_password" {
  type = string
  description = "Logstash system password used for xpack monitoring"
}

variable "logstash_internal_password" {
  type = string
  description = "Logstash internal password used for elasticsearch output"
}

variable "kibana_system_password" {
  type = string
  description = "Kibana system password used for communications with elasticsearch"
}

# cowrie
variable "cowrie_ssh_port" {
  type = string
  description = "Port for cowrie ssh service"
  default = "22"
}

variable "cowrie_telnet_port" {
  type = string
  description = "Port for cowrie telnet service"
  default = "23"
}

# ssh
variable "ssh_port" {
  type = string
  description = "Port to relocate ssh service to"
  default = "50220"
}
