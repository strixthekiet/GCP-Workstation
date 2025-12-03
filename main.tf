resource "google_service_account" "gcpce_vm_sa" {
  account_id   = "workstation-sa"
  display_name = "Workstation Service Account"
}

# get HCP terraform email or current user email, depends on where TF is executed
data "google_client_openid_userinfo" "me" {}

locals {
  os_login_user = replace(replace(data.google_client_openid_userinfo.me.email, "@", "_"), ".", "_")
}

output "ssh_user" {
  value = local.os_login_user
}

resource "google_os_login_ssh_public_key" "default" {
  user = data.google_client_openid_userinfo.me.email
  key  = var.ssh_key_pub
}
