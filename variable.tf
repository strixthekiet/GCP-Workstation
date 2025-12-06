variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_dns_records" {
  description = "List of DNS records to create/update in Cloudflare"
  type        = list(string)
  default     = []
}

variable "cloudflare_zone_id" {}

variable "dashboard_password" {
  description = "Password for the VM Manager Dashboard"
  type        = string
  sensitive   = false
}

variable "gcp_credentials" {
  description = "GCP service account credentials JSON"
  type        = string
  sensitive   = true
}

variable "project_id" {
}

variable "region" {
}

variable "ssh_key" {
  description = "SSH key file"
  sensitive = false
}

variable "ssh_key_pub" {
  description = "SSH key public file"
}

variable "ssh_user" {
  description = "user name to SSH to the VMs"
}

variable "zone_code" {
  validation {
    condition     = contains(["a", "b", "c"], var.zone_code)
    error_message = "zone-code must be 'a', 'b', or 'c'."
  }
}



variable "route-internet-via-npm-gateway-tag" {
  default = "route-internet-via-npm-gateway"
}

variable "npm_gateway_machine_type" {
  default = "e2-micro"
}

variable "npm_gateway_internal_ip" {
  default = "10.0.0.100"
}

variable "workstation_machine_type" {
  default = "e2-medium"
}

variable "workstation_internal_ip" {
  default = "10.0.0.101"

}

variable "jellyfin_server_machine_type" {
  default = "e2-highcpu-4"
}

variable "jellyfin_server_internal_ip" {
  default = "10.0.0.102"
}

variable "npm_gateway_name" {
  default = "npm-gateway"
}