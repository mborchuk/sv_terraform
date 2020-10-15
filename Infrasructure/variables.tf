variable "project_id" {
  description = "Google Project ID."
  type        = string
  default     = "solar-vortex-283516"
}

variable "name" {
  description = "Project name"
  type        = string
  default     = "k9"
}

variable "env_name" {
  description = "Name of environment"
  type = string
  default = "dev"
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1-a"
}

# Images for deploing
variable "image" {
  description = "Name of the docker image to deploy."
//  default     = "gcr.io/solar-vortex-283516/first_build"
  default     = "gcr.io/solar-vortex-283516/project-k9"
}

variable "tag" {
  description = "The docker image digest to deploy."
//  default     = "latest"
  default     = "0.0.24"
}

variable "main_cidr" {
  description = "IP range for main VPC"
  default     = "10.8.0.0/24"
}

variable "connector_cidr" {
  description = "IP range for main VPC"
  default     = "10.7.0.0/28"
}

variable "user_password" {
  description = "Password for user of database"
  default = ""
}

variable "user_name" {
  description = "Name of user for database"
  default = ""
}

variable "db_name" {
  description = "Name of user for database"
  default = ""
}

variable "db_charset" {
  description = "The charset value of database"
  default = "UTF8"
}

variable "db_collation" {
  description = "The collation value of database"
  default = "en_US.UTF8"
}

variable "service_link" {
  default = ""
}