# Create private key
resource "tls_private_key" "manuka" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create private key pem file
resource "local_file" "private_key_pem" {
  filename = "${path.module}/keys/private.pem"
  content = tls_private_key.manuka.private_key_pem
}

# Create public key pem file
resource "local_file" "public_key_pem" {
  filename = "${path.module}/keys/public.pem"
  content = tls_private_key.manuka.public_key_pem
}

# Create public key openssh file
resource "local_file" "public_key_openssh" {
  filename = "${path.module}/keys/id_rsa.pub"
  content = tls_private_key.manuka.public_key_openssh
}