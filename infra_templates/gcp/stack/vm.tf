###############################################################################
# COMPUTE RESOURCES
###############################################################################

# Bastion Host in Public Subnet
resource "google_compute_instance" "bastion" {
  name         = format("%s-%s-bastion", var.customer, var.environment)
  machine_type = var.bastion_type
  zone         = var.zone

  tags = ["bastion"]

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

  labels = merge(local.common_labels, {
    Type = "bastion"
  })

  depends_on = [google_compute_subnetwork.public_subnet]
}

# Jumpbox in Private Subnet
resource "google_compute_instance" "jumpbox" {
  name         = format("%s-%s-jumpbox", var.customer, var.environment)
  machine_type = var.jumpbox_type
  zone         = var.zone

  tags = ["jumpbox"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet_1.id
    // No access_config for private IP only
  }

  metadata = {
    ssh-keys = "ubuntu:${file(format("%s/id_%s.pub", var.ssh_keys_folder, var.customer))}"
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip
              EOF

  labels = merge(local.common_labels, {
    Type = "jumpbox"
  })

  depends_on = [google_compute_subnetwork.private_subnet_1]
}

# Backend VMs in Private Subnet (for_each over input list)
resource "google_compute_instance" "backend" {
  for_each = { for vm in var.medium_vms : vm.name => vm }

  name         = each.value.name
  machine_type = each.value.instance_type
  zone         = var.zone

  tags = ["backend"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = each.value.volume_size
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet_1.id
    // No access_config for private IP only
  }

  metadata = {
    ssh-keys = "ubuntu:${file(format("%s/id_%s.pub", var.ssh_keys_folder, var.customer))}"
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip
              EOF

  labels = merge(local.common_labels, {
    Type = "backend"
    Name = each.value.name
  })

  depends_on = [google_compute_subnetwork.private_subnet_1]
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