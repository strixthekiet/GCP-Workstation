# # Zip the source code
# data "archive_file" "function_source" {
#   type        = "zip"
#   source_dir  = "${path.module}/cloud-run-function"
#   output_path = "${path.module}/function-source.zip"
# }

# # Upload source code to Cloud Storage
# resource "google_storage_bucket" "function_bucket" {
#   name                        = "${var.project_id}-function-source"
#   location                    = var.region
#   uniform_bucket_level_access = true
# }

# resource "google_storage_bucket_object" "function_source" {
#   name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
#   bucket = google_storage_bucket.function_bucket.name
#   source = data.archive_file.function_source.output_path
# }

# # Service Account for the Function
# resource "google_service_account" "vm_manager_sa" {
#   account_id   = "vm-manager-sa"
#   display_name = "VM Manager Service Account"
# }

# # Grant permissions to start/stop instances
# resource "google_project_iam_member" "vm_manager_compute_admin" {
#   project = var.project_id
#   role    = "roles/compute.instanceAdmin.v1"
#   member  = "serviceAccount:${google_service_account.vm_manager_sa.email}"
# }

# # Cloud Run Function (2nd Gen)
# resource "google_cloudfunctions2_function" "vm_manager" {
#   name        = "vm-manager-function"
#   location    = var.region
#   description = "Manages VM states and serves dashboard"

#   build_config {
#     runtime     = "python311"
#     entry_point = "vm_manager" # Must match the function name in main.py
#     source {
#       storage_source {
#         bucket = google_storage_bucket.function_bucket.name
#         object = google_storage_bucket_object.function_source.name
#       }
#     }
#   }

#   service_config {
#     max_instance_count    = 1
#     available_memory      = "512M"
#     timeout_seconds       = 60
#     service_account_email = google_service_account.vm_manager_sa.email
#     environment_variables = {
#       PROJECT_ID       = var.project_id
#       ZONE             = provider::google::zone_from_id(google_compute_instance.workstation.id)
#       PASSWORD         = var.dashboard_password
#       NPM_GATEWAY_NAME = var.npm_gateway_name
#     }
#   }
# }

# # Allow unauthenticated access (protected by app-level password)
# resource "google_cloud_run_service_iam_member" "public_invoker" {
#   location = google_cloudfunctions2_function.vm_manager.location
#   service  = google_cloudfunctions2_function.vm_manager.name
#   role     = "roles/run.invoker"
#   member   = "allUsers"
# }

# output "vm_manager_url" {
#   value = google_cloudfunctions2_function.vm_manager.service_config[0].uri
# }
