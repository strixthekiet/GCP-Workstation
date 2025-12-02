terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>7.12.0"
    }
  }
  cloud {
    organization = "strixthekiet"
    workspaces {
      name = "strixthekiet-workstation"
    }
  }
}

provider "google" {
  project            = var.project_id
  region             = var.region
  zone               = "${var.region}-a"
  credentials        = var.gcp_credentials
}
