// Configure the Google Cloud provider
provider "google-beta" {
  credentials = file("sv-081a230b9967.json")
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

provider "google" {
  credentials = file("sv-081a230b9967.json")
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}