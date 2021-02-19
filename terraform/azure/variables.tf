variable "region" {
  default = "westus2"
}

# vm
variable "vmUser" {
    type = string
    description = "Username for virtual machine"
}

# cloud-init
variable "timezone" {
  default = "UTC"
}

variable "traefikUser" {
}

variable "traefikPassword" {
}

variable "kibanaUser" {
}

variable "kibanaPassword" {
}