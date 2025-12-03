data "google_compute_disk" "npm_gateway_pd" {
  name = "npm-gateway-pd"
}

resource "google_compute_instance" "npm_gateway" {
  can_ip_forward = true
  enable_display = false

  machine_type = var.npm_gateway_machine_type
  name         = "npm-gateway"

  boot_disk {
    auto_delete = true
    device_name = "npm-gateway-boot-disk"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20251121"
      size  = 10
      type  = "pd-standard"
    }
    mode = "READ_WRITE"
  }

  attached_disk {
    device_name = data.google_compute_disk.npm_gateway_pd.name
    source      = data.google_compute_disk.npm_gateway_pd.id
  }

  network_interface {
    access_config {
      network_tier = "STANDARD"
    }
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.vpc_subnet.id
    network_ip = var.npm_gateway_internal_ip
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
    type        = "ssh"
    host        = self.network_interface[0].access_config[0].nat_ip
    private_key = var.ssh_key
    user        = local.os_login_user
  }

  provisioner "file" {
    source      = "setup/setup-mount.sh"
    destination = "/home/${local.os_login_user}/setup-mount.sh"
  }

  provisioner "file" {
    source      = "setup/cloudflare-ddns.sh"
    destination = "/home/${local.os_login_user}/cloudflare-ddns.sh"
  }

  provisioner "file" {
    source      = "setup/npm-gateway-docker-compose.yml"
    destination = "/home/${local.os_login_user}/npm-gateway-docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf && sudo sysctl -p",
      "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections && echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent",
      "EXTERNAL_IFACE=$(ip route show default | awk '/default/ {print $5}' | head -1)",
      "sudo iptables -t nat -A POSTROUTING -o $EXTERNAL_IFACE -j MASQUERADE && sudo netfilter-persistent save",
      "sudo apt install -y curl cron",
      "chmod +x /home/${local.os_login_user}/setup-mount.sh && sudo /home/${local.os_login_user}/setup-mount.sh /npm-gateway-data ${data.google_compute_disk.npm_gateway_pd.name}",

      "chmod +x /home/${local.os_login_user}/cloudflare-ddns.sh && sudo /home/${local.os_login_user}/cloudflare-ddns.sh ${var.cloudflare_api_token} ${var.cloudflare_zone_id} ${join(" ", var.cloudflare_dns_records)}",
      "(crontab -l | { cat; echo \"@reboot /home/${local.os_login_user}/cloudflare-ddns.sh ${var.cloudflare_api_token} ${var.cloudflare_zone_id} ${join(" ", var.cloudflare_dns_records)} >/dev/null 2>&1\"; }) | crontab -",
      "crontab -l | { cat; echo \"*/10 * * * * /home/${local.os_login_user}/cloudflare-ddns.sh ${var.cloudflare_api_token} ${var.cloudflare_zone_id} ${join(" ", var.cloudflare_dns_records)} >/dev/null 2>&1\"; } | crontab -",

      "curl -fsSL https://get.docker.com | sudo sh && sudo docker compose -f /home/${local.os_login_user}/npm-gateway-docker-compose.yml up -d"
    ]
  }
}

output "npm_gateway_ip" {
  value = google_compute_instance.npm_gateway.network_interface[0].access_config[0].nat_ip
}
