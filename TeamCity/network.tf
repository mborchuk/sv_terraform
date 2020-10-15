resource "google_compute_network" "teamcity_vpc_network" {
  name = "vpc-network-${var.env_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "teamcity_subnetwork" {
  ip_cidr_range = var.main_cidr
  name = "${var.env_name}-subnetwork"
  network = google_compute_network.teamcity_vpc_network.self_link
  region = var.region
}

resource "google_compute_address" "teamcity_server-ip-external" {
  name = "external-ip-for-${var.name}"
  address_type = "EXTERNAL"
}

resource "google_compute_firewall" "teamcity-firewall-web" {
  name    = "teamcity-firewall-web"
  network = google_compute_network.teamcity_vpc_network.name
  target_tags = ["teamcity"]
//  source_ranges = var.allow_source_ips_to_teamcity
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "teamcity-firewall-ssh" {
  name    = "teamcity-firewall-ssh"
  network = google_compute_network.teamcity_vpc_network.name
  target_tags = ["ssh"]
//  source_ranges = var.allow_source_ips_to_teamcity
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
//
//resource "google_compute_managed_ssl_certificate" "teamcity_certificate" {
//  provider = google-beta
//
//  name = "${var.env_name}-cert"
//
//  managed {
//    domains = ["teamcity.coordinative.dev."]
//  }
//}
