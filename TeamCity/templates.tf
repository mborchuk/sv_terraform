resource "google_compute_instance_template" "agents_template" {
    name    = "agent-${var.env_name}"
//    name_prefix  = "agent-"
    tags    = ["agents"]
    
    labels  = {
        environment = var.env_name
    }
    metadata_startup_script   = data.template_file.startup_agents_script.rendered
    machine_type         = var.machine_type_agents
    can_ip_forward       = false

    metadata = {
        ssh-keys = "mykola.borchuk:${file("~/.ssh/id_rsa.pub")}"
    }

    disk {
//        source_image = "debian-cloud/debian-9"
        source_image = "ubuntu-os-cloud/ubuntu-minimal-1804-bionic-v20200824"
//        source_image = "ubuntu-os-cloud/ubuntu-minimal-2004-focal-v20200826"
        auto_delete  = true
        boot         = true
        disk_size_gb = 10
    }

    network_interface {
        subnetwork         = google_compute_subnetwork.teamcity_subnetwork.id
        subnetwork_project = var.project_id

        access_config {
            network_tier = "STANDARD"
        }
    }

    service_account {
        email = google_service_account.teamcity_server.email
//        scopes = [
//            "https://www.googleapis.com/auth/cloud-platform",
//        ]
        scopes = ["compute-ro", "storage-rw", "cloud-platform", "datastore"]
    }
}

data "template_file" "startup_agents_script" {
  template = file("${path.module}/templates/startup_agents.sh")

  vars = {
    server_address = google_compute_address.teamcity_server-ip-external.address
    server_name = "k9-teamcity.coordinative.dev"
//    server_address = google_compute_instance.teamcity_server.network_interface[0].network_ip
  }
}