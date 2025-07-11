###############################################################################
# VPC & SUBNETS
###############################################################################
resource "google_compute_network" "main" {
  name                    = format("%s-main-vpc", var.customer)
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = format("%s-public-subnet", var.customer)
  ip_cidr_range = var.public_subnet_cidr
  network       = google_compute_network.main.id
  region        = var.region

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "private_subnet_1" {
  name          = format("%s-private-subnet-1", var.customer)
  ip_cidr_range = var.private_subnet_1_cidr
  network       = google_compute_network.main.id
  region        = var.region

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "private_subnet_2" {
  name          = format("%s-private-subnet-2", var.customer)
  ip_cidr_range = var.private_subnet_2_cidr
  network       = google_compute_network.main.id
  region        = var.region

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

###############################################################################
# FIREWALL RULES
###############################################################################
resource "google_compute_firewall" "allow_ssh" {
  name    = format("%s-allow-ssh", var.customer)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion", "proxy"]
}

resource "google_compute_firewall" "allow_http" {
  name    = format("%s-allow-http", var.customer)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion", "proxy"]
}

resource "google_compute_firewall" "allow_https" {
  name    = format("%s-allow-https", var.customer)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion", "proxy"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = format("%s-allow-internal", var.customer)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
}

resource "google_compute_firewall" "allow_bastion_to_jumpbox" {
  name    = format("%s-bastion-to-jumpbox", var.customer)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["bastion"]
  target_tags = ["jumpbox"]
}

resource "google_compute_firewall" "allow_jumpbox_to_backend" {
  name    = format("%s-jumpbox-to-backend", var.customer)
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["jumpbox"]
  target_tags = ["backend"]
}

###############################################################################
# CLOUD NAT
###############################################################################
resource "google_compute_router" "router" {
  name    = format("%s-router", var.customer)
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "nat" {
  name                               = format("%s-nat", var.customer)
  router                            = google_compute_router.router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
} 