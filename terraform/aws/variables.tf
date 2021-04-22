# EC2
variable "EC2_Region" {
  default     = "eu-west-2"
}

variable "EC2_Instance_Type" {
  # t2.medium = 2 vCPU, 4 GiB RAM
  default = "t2.medium"
}

variable "EC2_SSH_Key_Name" {
  default = "Manuka"
}

# VPC
variable "VPC_CIDRBlock" {
  default = "10.0.0.0/16"
}

variable "VPC_SubnetCIDRBlock" {
  default = "10.0.2.0/24"
}

variable "VPC_InstanceTenancy" {
    default = "default"
}

variable "VPC_DNSSupport" {
    default = true
}

variable "VPC_DNSHostNames" {
    default = true
}

variable "VPC_MapPublicIP" {
    default = true
}

# cloud-init
variable "timezone" {
  default = "UTC"
}

variable "traefikUser" {
  default = "traefik"
}

variable "traefikPassword" {
}

variable "kibanaUser" {
  default = "kibana"
}

variable "kibanaPassword" {
}