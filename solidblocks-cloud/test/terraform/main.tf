resource "random_string" "test_id" {
  length  = 16
  special = false
  lower   = true
  upper   = false
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "ssh_key" {
  name       = "test-${random_string.test_id.id}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource hcloud_server "test" {
  name        = "test-${random_string.test_id.id}"
  image       = "debian-11"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.ssh_key.id]
  location    = "nbg1"
  user_data   = file("${path.module}/../../build/documentation/generated/cloud_minimal_skeleton")
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = "${path.module}/test_id_rsa"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "${path.module}/test_id_rsa.pub"
  file_permission = "0600"
}

resource "local_file" "ssh_public_config" {
  content = templatefile("${path.module}/ssh_config.template", {
    "hostname"      = hcloud_server.test.ipv4_address
    "identity_file" = abspath(local_file.ssh_private_key.filename)
  }
  )
  filename        = "${path.module}/ssh_config"
  file_permission = "0600"
}

resource "aws_s3_bucket" "bootstrap" {
  bucket = "test-${random_string.test_id.id}"
}

resource "aws_s3_object" "bootstrap" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "pellepelster/solidblocks/releases/download/${var.solidblocks_version}/solidblocks-cloud-${var.solidblocks_version}.zip"
  source = "${path.module}/../../build/solidblocks-cloud-snapshot.zip"
  acl    = "public-read"
  #etag = filemd5("path/to/file")
}