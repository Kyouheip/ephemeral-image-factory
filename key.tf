resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "sd_key" {
  key_name   = "sd-forge-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/sd-forge-key.pem"
  file_permission = "0600"
}
