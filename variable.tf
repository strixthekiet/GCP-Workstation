variable "gcp_credentials" {
  description = "GCP service account credentials JSON"
  type        = string
  sensitive   = true
}

variable "project_id" {
}

variable "region" {
}

variable "route-internet-via-npm-gateway-tag" {
  default = "route-internet-via-npm-gateway"
}


variable "cloudflare_zone_id" {}

variable "cloudflare_api_token" {}

variable "cloudflare_dns_records" {
  description = "List of DNS records to create/update in Cloudflare"
  type        = list(string)
  default     = []
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

variable "dashboard_password" {
  description = "Password for the VM Manager Dashboard"
  type        = string
  sensitive   = true
}

variable "npm_gateway_name" {
  default = "npm-gateway"
}