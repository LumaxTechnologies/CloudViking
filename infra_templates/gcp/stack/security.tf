###############################################################################
# IAM ROLES & SERVICE ACCOUNTS
###############################################################################

# Service Account for Jumpbox
resource "google_service_account" "jumpbox_sa" {
  account_id   = format("%s-jumpbox-sa", var.customer)
  display_name = format("%s Jumpbox Service Account", var.customer)
  description  = "Service account for jumpbox instance"
}

# Service Account for Backend VMs
resource "google_service_account" "backend_sa" {
  account_id   = format("%s-backend-sa", var.customer)
  display_name = format("%s Backend Service Account", var.customer)
  description  = "Service account for backend instances"
}

# IAM Role for Database Access
resource "google_project_iam_member" "jumpbox_db_access" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.jumpbox_sa.email}"
}

# IAM Role for Secret Manager Access
resource "google_project_iam_member" "jumpbox_secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.jumpbox_sa.email}"
}

# IAM Role for Backend VMs
resource "google_project_iam_member" "backend_compute_access" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.backend_sa.email}"
}

# Service Account Key for Jumpbox (if needed)
resource "google_service_account_key" "jumpbox_key" {
  service_account_id = google_service_account.jumpbox_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Service Account Key for Backend (if needed)
resource "google_service_account_key" "backend_key" {
  service_account_id = google_service_account.backend_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
} 