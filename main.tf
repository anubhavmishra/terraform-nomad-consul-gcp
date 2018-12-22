provider "google" {
  project = "${var.project_id}"
  region  = "${var.region}"
}

data "google_compute_zones" "available" {}

data "google_compute_image" "base" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-1604-lts"
}

# SSH private and public key
resource "tls_private_key" "key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "null_resource" "save-key" {
  triggers {
    key = "${tls_private_key.key.private_key_pem}"
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.key.private_key_pem}" > ${path.module}/.ssh/id_rsa
      chmod 0600 ${path.module}/.ssh/id_rsa
EOF
  }
}
