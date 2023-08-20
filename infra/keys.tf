resource "tls_private_key" "demo_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.env}-key"
  public_key = tls_private_key.demo_key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.demo_key.private_key_pem}' > ./${var.env}-key.pem"
  }
}

