data "template_file" "nomad_consul_server" {
  count = "3"

  template = <<EOF
${file("${path.module}/templates/common/provision.sh")}
${file("${path.module}/templates/nomad-server.sh")}
${file("${path.module}/templates/consul-server.sh")}
EOF

  vars {
    username       = "${var.username}"
    consul_version = "${var.consul_version}"
    nomad_version  = "${var.nomad_version}"
    datacenter     = "${var.datacenter}"
    region         = "${var.nomad_region}"
    project_id     = "${var.project_id}"
    retry_join_tag = "${var.retry_join_tag}"
  }
}

data "template_file" "nomad_client" {
  count = "2"

  template = <<EOF
${file("${path.module}/templates/common/provision.sh")}
${file("${path.module}/templates/nomad-client.sh")}
EOF

  vars {
    username       = "${var.username}"
    consul_version = "${var.consul_version}"
    nomad_version  = "${var.nomad_version}"
    datacenter     = "${var.datacenter}"
    region         = "${var.nomad_region}"
    project_id     = "${var.project_id}"
    retry_join_tag = "${var.retry_join_tag}"
  }
}

resource "google_compute_instance" "nomad_consul_server" {
  count = "3"

  name         = "nomad-consul-${var.datacenter}-${count.index+1}"
  machine_type = "n1-standard-2"
  zone         = "${data.google_compute_zones.available.names[0]}"

  tags = ["instance", "${var.retry_join_tag}"]

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base.self_link}"
      type  = "pd-ssd"
      size  = "60"
    }
  }

  network_interface {
    network       = "default"
    access_config = {}        # Public-facing IP
  }

  metadata {
    ssh-keys = "${var.username}:${trimspace(tls_private_key.key.public_key_openssh)} ${var.username}@livedemos.xyz"
  }

  metadata_startup_script = "${element(data.template_file.nomad_consul_server.*.rendered, count.index)}"

  service_account {
    scopes = ["compute-ro"]
  }
}

resource "google_compute_instance" "nomad_client" {
  count = "2"

  name         = "nomad-client-${var.datacenter}-${count.index+1}"
  machine_type = "n1-standard-1"
  zone         = "${data.google_compute_zones.available.names[0]}"

  tags = ["instance"]

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base.self_link}"
      type  = "pd-ssd"
      size  = "60"
    }
  }

  network_interface {
    network       = "default"
    access_config = {}        # Public-facing IP
  }

  metadata {
    ssh-keys = "${var.username}:${trimspace(tls_private_key.key.public_key_openssh)} ${var.username}@livedemos.xyz"
  }

  metadata_startup_script = "${element(data.template_file.nomad_client.*.rendered, count.index)}"

  service_account {
    scopes = ["compute-ro"]
  }
}

##### OUTPUTS #####

output "nomad_consul_server_ips" {
  value = "${google_compute_instance.nomad_consul_server.*.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "nomad_client_ips" {
  value = "${google_compute_instance.nomad_client.*.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "nomad_consul_server_ssh" {
  value = "ssh -q -i ${path.module}/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no demo@${google_compute_instance.nomad_consul_server.0.network_interface.0.access_config.0.assigned_nat_ip} -L 4646:localhost:4646 -L 8500:localhost:8500"
}
