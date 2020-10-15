# Create a Cloud Run service
resource "google_cloud_run_service" "service" {
  name     = "${var.name}-${var.env_name}-service"
  location = var.region

  depends_on = [google_vpc_access_connector.k9_vpc_connector]

  metadata {
    namespace = var.project_id
//    annotations = {
//      "run.googleapis.com/vpc-access-connector" = "${google_vpc_access_connector.sv_vpc_connector.self_link}"
//    }
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "1000"
//        "run.googleapis.com/cloudsql-instances" = "${var.project_id}:${var.region}:${google_sql_database_instance.k9-postgres.name}"
        "run.googleapis.com/cloudsql-instances" = "${google_sql_database_instance.k9-postgres.connection_name}"
        "run.googleapis.com/vpc-access-connector" = "${google_vpc_access_connector.k9_vpc_connector.name}"
        "run.googleapis.com/client-name"          = "terraform"
      }
    }
    spec {
      timeout_seconds = 90
      containers {
        image = "${var.image}:${var.tag}"
        env {
          name  = "WEB_SERVER_PORT"
          value = "8080"
        }
        env {
          name = "MODE"
          value = "production"
        }
        env {
          name = "ENABLE_SWAGGER"
          value = "true"
        }
        env {
          name = "DB_HOST"
//          value = "127.0.0.1"
//          value = "/cloudsql/${google_sql_database_instance.k9-postgres.connection_name}/.s.PGSQL.5432"
          value = google_sql_database_instance.k9-postgres.private_ip_address
        }
        env {
          name = "DB_PORT"
          value = "5432"
        }
        env {
          name = "DB_USERNAME"
          value = google_sql_user.k9-default-database-user.name
        }
        env {
          name = "DB_PASSWORD"
          value = google_sql_user.k9-default-database-user.password
        }
        env {
          name = "DB_DATABASE"
          value = google_sql_database.k9-default-database.name
        }
        env {
          name = "K9_BROWSER_BASE_URL"
//          value = "${google_cloud_run_service.service.status[0].url}"
          value = var.service_link == "" ? "" : "https://${var.name}-${var.env_name}-${var.service_link}"
        }
        env {
          name = "K9_BASE_URL"
//          value = "${google_cloud_run_service.service.status[0].url}"
          value = var.service_link == "" ? "" : "https://${var.name}-${var.env_name}-${var.service_link}"
        }
        env {
          name = "ENABLE_NUXT_BUILD"
          value = "false"
        }
        env {
          name = "K9_VAULT_ENDPOINT"
          value = "https://that.school:8200"
        }
        env {
          name = "K9_VAULT_ROLE"
          value = "7afc392d-44e6-6ccc-c3f7-29cc755acdd1"
        }
        env {
          name = "K9_VAULT_SECRET"
          value = "ed761c14-6e3b-42ed-a94b-f17f22141004"
        }
        env {
          name = "K9_JWT_PUBLIC"
          value = "vault://k9/jwt/public"
        }
        env {
          name = "K9_JWT_SECRET"
          value = "vault://k9/jwt/secret"
        }

        resources {
          limits = {
            cpu    = "2000m"
            memory = "2048Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Create public access
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Enable public access on Cloud Run service
resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.service.location
#  project     = google_cloud_run_service.service.project
  service     = google_cloud_run_service.service.name
  policy_data = data.google_iam_policy.noauth.policy_data
  # role     = "roles/run.invoker"
  # member   = "allUsers"
}

//resource "google_compute_region_network_endpoint_group" "neg_cloud_run" {
//  name         = "sv-${var.env_name}-neg"
//  network_endpoint_type = "SERVERLESS"
//  region         = "${var.region}"
//  cloud_run {
//    service = "sv-${var.env_name}-service"
//    tag = "${var.tag}" # Optional
////    url_mask = ".coordinative.dev/"
//  }
//}


resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "k9-postgres" {
  provider = google-beta
  database_version = "POSTGRES_12"
  name   = "${var.name}-postgres-db-${var.env_name}-${random_id.db_name_suffix.hex}"
  region = var.region
  project = var.project_id

  depends_on = [google_service_networking_connection.db_private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.k9_vpc_network.id
    }
  }
}

//resource "google_compute_network" "db_private_network" {
//  provider = google-beta
//  project = var.project_id
//  auto_create_subnetworks = false
//  delete_default_routes_on_create = true
//
//  name = "${var.name}-network-db-${var.env_name}"
//}

resource "random_id" "user-password" {
  keepers = {
    name = google_sql_database_instance.k9-postgres.name
  }

  byte_length = 8
  depends_on  = [google_sql_database_instance.k9-postgres]
}

resource "google_sql_database" "k9-default-database" {
  name       = var.db_name == "" ? "${var.name}-dbpg-${var.env_name}" : var.db_name
  project    = var.project_id
  instance   = google_sql_database_instance.k9-postgres.name
  charset    = var.db_charset
  collation  = var.db_collation
  depends_on = [google_sql_database_instance.k9-postgres]
}

resource "google_sql_user" "k9-default-database-user" {
  name       = var.user_name == "" ? "${var.name}-dbuser-${var.env_name}" : var.user_name
  project    = var.project_id
  instance   = google_sql_database_instance.k9-postgres.name
  password   = var.user_password == "" ? random_id.user-password.hex : var.user_password
  depends_on = [google_sql_database_instance.k9-postgres]
}
