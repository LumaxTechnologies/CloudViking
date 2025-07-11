###############################################################################
# COMPUTE RESOURCES
###############################################################################

# Proxy Host in Public Subnet
resource "google_compute_instance" "proxy" {
  name         = format("%s-%s-proxy", var.customer, var.environment)
  machine_type = var.proxy_type
  zone         = var.zone

  tags = ["proxy"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(format("%s/id_%s.pub", var.ssh_keys_folder, var.customer))}"
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip
              EOF

  labels = local.common_labels

  depends_on = [google_compute_subnetwork.public_subnet]
}

###############################################################################
# SSH KEYS
###############################################################################
resource "google_compute_project_metadata" "ssh_keys" {
  for_each = var.ssh_keys
  
  metadata = {
    ssh-keys = "ubuntu:${file(format("%s/id_%s.pub", var.ssh_keys_folder, each.value.name))}"
  }
} 