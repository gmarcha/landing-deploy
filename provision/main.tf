terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.76.0"
    }
  }
}

provider "google" {
  project     = var.project
  credentials = file(var.credentials_file)

  region = var.region
  zone   = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                    = "${var.name}-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = "${var.name}-subnetwork"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_address" "vm_ipv4_address" {
  name = "${var.name}-ipv4-address"
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.name}-allow-ssh"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "http" {
  name    = "${var.name}-allow-http"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http"]
}

resource "google_compute_firewall" "https" {
  name    = "${var.name}-allow-https"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https"]
}

resource "google_compute_firewall" "tcp_6443" {
  name    = "${var.name}-allow-tcp-6443"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["tcp-6443"]
}

resource "google_compute_firewall" "tcp_8080" {
  name    = "${var.name}-allow-tcp-8080"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["tcp-8080"]
}

resource "google_compute_instance" "vm_instance" {
  name                      = "${var.name}-instance"
  machine_type              = var.machine_type
  allow_stopping_for_update = true
  tags                      = ["ssh", "http", "https"]
  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.vpc_subnetwork.id
    access_config {
      nat_ip = google_compute_address.vm_ipv4_address.address
    }
  }
  metadata_startup_script = <<-EOF

    dnf install -y epel-release
    dnf install -y ansible

    echo "${file("../config.yaml")}" > /usr/local/src/config.yaml

    ansible-pull \
      -U https://${var.repository_user}:${var.repository_password}@${var.repository_host}/${var.repository_name} \
      -i localhost, \
      -d /usr/local/src/landing-deploy \
      -vv \
      --extra-vars "@/usr/local/src/config.yaml" \
      /usr/local/src/landing-deploy/config/primary.yaml
  EOF

  # https://cloud.google.com/compute/docs/instances/startup-scripts/linux#viewing-output
  # - restart script: sudo google_metadata_script_runner startup
  # - inspect logs: sudo journalctl -eu google-startup-scripts.service
}

output "External-IP" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}

output "External-URL" {
  value = join("", ["http://", google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip])
}
