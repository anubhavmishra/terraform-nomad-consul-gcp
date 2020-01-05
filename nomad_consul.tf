data "template_file" "nomad_consul_server" {
  count = "3"

  template = <<EOF
${file("${path.module}/templates/common/provision.sh")}
${file("${path.module}/templates/nomad-server.sh")}
${file("${path.module}/templates/consul-server.sh")}
EOF


  vars = {
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

  vars = {
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

  tags = ["nomad-consul-server", "${var.retry_join_tag}"]

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base.self_link}"
      type  = "pd-ssd"
      size  = "60"
    }
  }

  network_interface {
    network       = "default"
    access_config {}        # Public-facing IP
  }

  metadata = {
    ssh-keys = "${var.username}:${trimspace(tls_private_key.key.public_key_openssh)} ${var.username}@livedemos.xyz"
  }

  metadata_startup_script = "${element(data.template_file.nomad_consul_server.*.rendered, count.index)}"

  service_account {
    scopes = ["compute-ro"]
  }
}

module "lb" {
  source = "github.com/anubhavmishra/terraform-google-load-balancer//modules/network-load-balancer"

  name    = "nomad-consul-grid-external-ingress-lb"
  region  = var.region
  project = var.project_id

  enable_health_check = true
  health_check_port   = "8081"
  health_check_path   = "/ping"

  firewall_target_tags = var.nomad_client_tags

  instances = google_compute_instance.nomad_client.*.self_link
}

resource "google_compute_instance" "nomad_client" {
  count = "3"

  name         = "nomad-client-${var.datacenter}-${count.index+1}"
  machine_type = "n1-standard-2"
  zone         = "${data.google_compute_zones.available.names[0]}"

  tags = var.nomad_client_tags
  
  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base.self_link}"
      type  = "pd-ssd"
      size  = "60"
    }
  }

  network_interface {
    network       = "default"
    access_config {}        # Public-facing IP
  }

  metadata = {
    ssh-keys = "${var.username}:${trimspace(tls_private_key.key.public_key_openssh)} ${var.username}@livedemos.xyz"
  }

  metadata_startup_script = "${element(data.template_file.nomad_client.*.rendered, count.index)}"

  service_account {
    scopes = ["compute-ro"]
  }
}

resource "google_compute_firewall" "firewall" {
  project = var.project_id
  name    = "nomad-consul-grid-external-ingress-allow-all-http-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  allow {
    protocol = "tcp"
    ports    = ["8081"]
  }

  # These IP ranges are required for health checks
  source_ranges = ["0.0.0.0/0"]

  # Target tags define the instances to which the rule applies
  target_tags = var.nomad_client_tags
}

##### OUTPUTS #####

output "nomad_consul_server_ips" {
  value = "${google_compute_instance.nomad_consul_server.*.network_interface.0.access_config.0.nat_ip}"
}

output "nomad_client_ips" {
  value = "${google_compute_instance.nomad_client.*.network_interface.0.access_config.0.nat_ip}"
}

output "nomad_consul_server_ssh" {
  value = "ssh -q -i ${path.module}/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no demo@${google_compute_instance.nomad_consul_server.0.network_interface.0.access_config.0.nat_ip} -L 4646:localhost:4646 -L 8500:localhost:8500"
}
