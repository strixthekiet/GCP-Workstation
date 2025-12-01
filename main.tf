locals {
  zone          = "${var.region}-b"
  os_login_user = replace(replace(data.google_client_openid_userinfo.me.email, "@", "_"), ".", "_")
}

resource "google_service_account" "gcpce_vm_sa" {
  account_id   = "workstation-sa"
  display_name = "Workstation Service Account"
}

# resource "google_project_iam_member" "storage_access" {
#  project = var.project_id
#  role    = "roles/storage.admin"
#  member  = "serviceAccount:${google_service_account.gcpce_vm_sa.email}"
# }

data "google_client_openid_userinfo" "me" {
}

resource "google_os_login_ssh_public_key" "default" {
  user = data.google_client_openid_userinfo.me.email
  key  = file("key.pub") # path/to/ssl/id_rsa.pub
}

