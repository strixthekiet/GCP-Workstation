data "google_compute_disk" "workstation_pd" {
  name = "workstation-pd"
  zone = local.zone
}

resource "google_compute_instance" "workstation" {
  can_ip_forward = false
  enable_display = false
  machine_type   = var.workstation_machine_type
  name           = "workstation"
  zone           = local.zone
  tags           = [var.route-internet-via-npm-gateway-tag]

  boot_disk {
    auto_delete = true
    device_name = "workstation-boot-disk"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20251121"
      size  = 20
      type  = "pd-standard"
    }
    mode = "READ_WRITE"
  }

  attached_disk {
    device_name = data.google_compute_disk.workstation_pd.name
    source      = data.google_compute_disk.workstation_pd.id
  }

  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.vpc_subnet.id
    network_ip = var.workstation_internal_ip
  }

  scheduling {
    automatic_restart           = false
    preemptible                 = true
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  metadata = {
    enable-osconfig = "TRUE"
    enable-oslogin  = "true"
  }

  service_account {
    email  = google_service_account.gcpce_vm_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  connection {
    type                = "ssh"
    host                = self.network_interface[0].network_ip
    private_key         = file("key")
    user                = local.os_login_user
    bastion_host        = google_compute_instance.npm_gateway.network_interface[0].access_config[0].nat_ip
    bastion_user        = local.os_login_user
    bastion_private_key = file("key")
  }

  provisioner "file" {
    source      = "setup/setup-mount.sh"
    destination = "/home/${local.os_login_user}/setup-mount.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y curl wget git",
      "chmod +x /home/${local.os_login_user}/setup-mount.sh && sudo /home/${local.os_login_user}/setup-mount.sh /workstation-data ${data.google_compute_disk.workstation_pd.name}",
      "curl -fsSL https://get.docker.com | sudo sh",
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\" && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
    ]
  }
}
