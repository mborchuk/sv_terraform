//resource "google_compute_managed_ssl_certificate" "default" {
//  provider = google-beta
//
//  name = "${var.name}-${var.env_name}-cert"
//
//  managed {
//    domains = ["k9.coordinative.dev."]
//  }
//}