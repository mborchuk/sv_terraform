resource "google_compute_network" "k9_vpc_network" {
  name = "vpc-network-${var.name}-${var.env_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k9_subnetwork" {
  ip_cidr_range = var.main_cidr
  name = "${var.name}-${var.env_name}-subnetwork"
  network = google_compute_network.k9_vpc_network.self_link
  region = var.region
}

resource "google_compute_global_address" "k9-ip-address-static" {
  name = "${var.name}-external-ip-${var.env_name}"
  address_type = "EXTERNAL"
  ip_version = "IPV4"
  network = ""
}

resource "google_vpc_access_connector" "k9_vpc_connector" {
  name = "${var.name}-vpc-connector-${var.env_name}"
  region = var.region
  ip_cidr_range = var.connector_cidr
  network = google_compute_network.k9_vpc_network.name
}

resource "google_compute_global_address" "db_private_ip_address" {
  provider = google-beta
  project = var.project_id

  name          = "${var.name}-db-ip-address-${var.env_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.k9_vpc_network.id
}

resource "google_service_networking_connection" "db_private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.k9_vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.db_private_ip_address.name]
}

resource "google_compute_firewall" "k9-postgres-firewall" {
  name = "${var.name}-access-to-db-${var.env_name}"
  network = google_compute_network.k9_vpc_network.name

  allow {
    protocol = "all"
  }

  source_ranges = [google_compute_subnetwork.k9_subnetwork.ip_cidr_range]
}

resource "google_compute_firewall" "k9-postgres-firewall-2" {
  name = "${var.name}-access-to-db-${var.env_name}-2"
  network = google_compute_network.k9_vpc_network.name

  allow {
    protocol = "all"
  }

  source_ranges = [google_vpc_access_connector.k9_vpc_connector.ip_cidr_range]
}