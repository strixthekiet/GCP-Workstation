# VM Manager & Home Lab Infrastructure

A comprehensive Terraform-managed infrastructure for running a personal Home Lab on Google Cloud Platform (GCP). This project provisions a secure network, a media server (Jellyfin), a reverse proxy gateway (Nginx Proxy Manager), and a custom Cloud Run-based dashboard to manage VM states to save costs.

## Architecture

- **Nginx Proxy Manager (Gateway)**: Acts as the entry point and NAT gateway for the private network. It handles SSL termination and routing.
- **Jellyfin Server**: A high-performance media server running on a cost-effective spot instance (or standard VM).
- **Workstation**: A general-purpose VM for remote development or administration.
- **VM Manager**: A serverless Python application (Cloud Run Function) that provides a web dashboard to start/stop VMs on demand.
- **Networking**: A custom VPC with private subnets. VMs (except the gateway) do not have public IPs and route traffic through the gateway.

## Features

- **Cost Optimization**: Easily toggle expensive VMs (like the media server) via the web dashboard.
- **Security**: Private networking by default. Access is controlled via the gateway and the password-protected dashboard.
- **Automation**: Full Infrastructure as Code (IaC) using Terraform.
- **User Interface**: A clean, responsive web interface for managing your lab.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (gcloud)
- A GCP Project with billing enabled.
- A Cloudflare account (for DNS management).

## Setup Guide

### 1. Clone the Repository

```bash
git clone https://github.com/strixthekiet/GCP-workstation.git
cd GCP-workstation.git
```

### 2. Configure Variables

Copy the example configuration file:

```bash
cp terraform.tfvars.example production.tfvars
```

Edit `production.tfvars` with your specific details:

- `project_id`: Your GCP Project ID.
- `region`: Preferred GCP region (e.g., `asia-southeast1`).
- `cloudflare_zone_id` & `cloudflare_api_token`: For automated DNS records.
- `dashboard_password`: A strong password for the VM Manager dashboard.

### 3. Deploy Infrastructure

Initialize Terraform:

```bash
terraform init
```

Preview the changes:

```bash
terraform plan -var-file="production.tfvars"
```

Apply the configuration:

```bash
terraform apply -var-file="production.tfvars"
```

### 4. Access the Dashboard

After deployment, Terraform will output the `vm_manager_url`. Open this URL in your browser and log in with the `dashboard_password` you configured.

## 🔧 Development

### VM Manager Function

The dashboard code is located in `cloud-run-function/`. It uses Flask and the Google Cloud Compute library.

To test locally:

1. Create a virtual environment: `python3 -m venv .venv && source .venv/bin/activate`
2. Install dependencies: `pip install -r cloud-run-function/requirements.txt`
3. Run the app (requires GCP credentials): `python3 cloud-run-function/main.py`

## 📄 License

This project is licensed under the MIT License.

## Post-Setup

### Jellyfin Server

After the Jellyfin server is deployed, you can SSH into it to set up qBittorrent.

1.  Install qBittorrent-nox:
    ```bash
    sudo apt install qbittorrent-nox -y
    ```

2.  Run it once to accept the terms of service and get the initial password.
    ```bash
    qbittorrent-nox
    ```

3.  Set qBittorrent-nox to run on startup:
    ```bash
    crontab -l | { cat; echo '@reboot qbittorrent-nox -d'; } | crontab -
    ```
