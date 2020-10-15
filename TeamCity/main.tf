locals {
  # Conform to CIS 4.2
  required_metadata = {
    "block-project-ssh-keys" = "true"
  }

  data_device_name = "teamcity-data"
  data_mount_path  = "/mnt/data"

  base_metadata = {
    teamcity_version = var.teamcity_tag
  }

  key_metadata = {
    ssh-keys = "mykola.borchuk:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "google_compute_instance" "teamcity_server" {
  name         = var.name
  machine_type = var.machine_type_server
  zone         = var.zone
  description  = var.description
  project      = var.project_id

  tags                      = var.tags_teamcity_server
  labels                    = var.labels
  metadata                  = merge(local.base_metadata, var.metadata, local.required_metadata, local.key_metadata)
  metadata_startup_script   = data.template_file.startup_script.rendered
  allow_stopping_for_update = var.allow_stopping_for_update

  service_account {
    email = google_service_account.teamcity_server.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  boot_disk {
    initialize_params {
      size = var.boot_disk_size_gb
      type = var.boot_disk_type
//      image = coalesce(
//        var.boot_disk_image,
//        data.google_compute_image.teamcity_server.self_link,
//      )
      image = "ubuntu-os-cloud/ubuntu-minimal-1804-lts"
//      image = "ubuntu-os-cloud/ubuntu-minimal-2004-lts"
    }
  }

  network_interface {
    subnetwork         = google_compute_subnetwork.teamcity_subnetwork.id
    subnetwork_project = var.project_id
    network_ip         = var.network_ip

    access_config {
      nat_ip = google_compute_address.teamcity_server-ip-external.address
    }

    dynamic "access_config" {
      # Ephemeral IP address
      for_each = var.is_publicly_accessible ? [var.is_publicly_accessible] : []
      content {}
    }
  }

  attached_disk {
    source      = google_compute_disk.teamcity_server_data.self_link
    device_name = local.data_device_name
    mode        = "READ_WRITE"
  }
}

resource "google_compute_disk" "teamcity_server_data" {
  name        = var.data_disk_name
  description = "Disk holding the data for the TeamCity server instance ${var.name}"

  labels  = var.labels
  size    = var.data_disk_size
  type    = var.data_disk_type
  zone    = var.zone
  project = var.project_id

  lifecycle {
    prevent_destroy = true
  }
}

//data "google_compute_image" "teamcity_server" {
//  family  = var.boot_disk_family
//  project = coalesce(var.boot_disk_image_project, var.project_id)
//}

resource "google_service_account" "teamcity_server" {
  account_id   = var.name
  display_name = var.description
  project      = var.project_id
}

resource "google_project_iam_member" "teamcity_server" {
  for_each = var.service_account_roles

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.teamcity_server.email}"
}

data "template_file" "startup_script" {
  template = file("${path.module}/templates/startup.sh")

  vars = {
    data_device_name = local.data_device_name
    data_mount_path  = local.data_mount_path
    compose_config   = data.template_file.compose_config.rendered
    webserver_config = data.template_file.webserver_config.rendered
  }
}

data "template_file" "compose_config" {
  template = file("${path.module}/templates/docker-compose.yml")

  vars = {
    volume_base_path        = local.data_mount_path
    teamcity_port           = var.teamcity_port
    teamcity_image          = var.teamcity_image
    teamcity_tag            = var.teamcity_tag
    teamcity_memory_options = var.teamcity_memory_options
    external_domain         = var.external_domain
  }
}

data "template_file" "webserver_config" {
  template = file("${path.module}/templates/webserver-conf")

  vars = {
    external_domain         = var.external_domain
  }
}
