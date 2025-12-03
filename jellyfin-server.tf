# enable this if you want to use an existing disk as boot disk
# data "google_compute_disk" "jellyfin_server_bd" {
#   name = "jellyfin-server"
# }

data "google_compute_disk" "media_pd" {
  name = "media-pd"
}

resource "google_compute_instance" "jellyfin_server" {
  can_ip_forward = false
  enable_display = false
  machine_type   = var.jellyfin_server_machine_type
  name           = "jellyfin-server"
  tags           = [var.route-internet-via-npm-gateway-tag]

  # guest_accelerator {
  #   count = 1
  #   type  = "projects/strixthekiet-me/zones/asia-southeast1-b/acceleratorTypes/nvidia-tesla-p4"
  # }


  # enable this if you want to use an existing disk as boot disk
  # boot_disk {
  #   auto_delete = false
  #   device_name = "jellyfin-server-boot-disk"
  #   mode        = "READ_WRITE"
  #   source      = data.google_compute_disk.jellyfin_server_bd.id
  # }

  # enable this to create a new boot disk from image
  boot_disk {
    auto_delete = false
    mode = "READ_WRITE"
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20251121"
      size  = 10
      type  = "pd-standard"
    }
  }

  attached_disk {
    device_name = data.google_compute_disk.media_pd.name
    source      = data.google_compute_disk.media_pd.id
  }

  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.vpc_subnet.id
    network_ip = var.jellyfin_server_internal_ip
  }

  scheduling {
    automatic_restart           = false
    preemptible                 = true
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  metadata = {
    enable-osconfig = "TRUE"
    enable-oslogin  = "false"
    ssh-keys        = "terraform:${var.ssh_key_pub}\ndeveloper:${var.ssh_key_pub}"
  }

  service_account {
    email  = google_service_account.gcpce_vm_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  connection {
    type                = "ssh"
    host                = self.network_interface[0].network_ip
    private_key         = var.ssh_key
    user                = "terraform"
    bastion_host        = google_compute_instance.npm_gateway.network_interface[0].access_config[0].nat_ip
    bastion_user        = "terraform"
    bastion_private_key = var.ssh_key
  }

  # enable this to setup jellyfin server on first boot
  provisioner "file" {
    source      = "setup/setup-mount.sh"
    destination = "/home/terraform/setup-mount.sh"
  }

  # enable this to setup jellyfin server on first boot
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y curl iproute2 ufw cron",
      "sudo ufw allow 8096",
      "chmod +x /home/terraform/setup-mount.sh && sudo /home/terraform/setup-mount.sh /media ${data.google_compute_disk.media_pd.name}",
      "sudo chmod -R 777 /media",
      "curl -s https://repo.jellyfin.org/install-debuntu.sh -o /tmp/jellyfin-install.sh && sudo chmod +x /tmp/jellyfin-install.sh",
      "sudo -E SKIP_CONFIRM=true /tmp/jellyfin-install.sh",
      "sudo systemctl enable jellyfin",
    ]
  }
}