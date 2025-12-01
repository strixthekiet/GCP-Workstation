resource "google_compute_network" "vpc_network" {
  name                    = "main-vpc-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project_id
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "main-vpc-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc_network.id
  region        = var.region
  project       = var.project_id
}

resource "google_compute_firewall" "allow-common-ports" {
  name    = "allow-common-ports"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_route" "route-internet-via-npm-gateway" {
  name              = var.route-internet-via-npm-gateway-tag
  network           = google_compute_network.vpc_network.name
  dest_range        = "0.0.0.0/0"
  next_hop_instance = google_compute_instance.npm_gateway.id
  priority          = 900
  tags              = [var.route-internet-via-npm-gateway-tag]
}
