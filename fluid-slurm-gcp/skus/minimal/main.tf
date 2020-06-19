
terraform {
  backend "gcs" {
    bucket  = "managed-fluid-slurm-gcp-customer-tfstates"
    prefix  = "@ORG@/fluid-slurm-gcp"
  }
}

// Configure the Google Cloud provider
provider "google" {
 version = "3.9"
}

// Mark the Controller project as the Shared VPC Host Project
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.controller.project
}

// TO DO : Obtain a unique list of projects from the partitions
// Mark the Shared VPC Service Projects
resource "google_compute_shared_vpc_service_project" "service" {
  for_each = var.shared_vpc_service_projects
  host_project = var.shared_vpc_host_project
  service_project = each.key
  depends_on = [google_compute_shared_vpc_host_project.host]
}

// Create the Shared VPC Network
resource "google_compute_network" "shared_vpc_network" {
  name = "${var.slurm_gcp_name}-shared-network"
  project = var.controller.project
  auto_create_subnetworks = false
  depends_on = [google_compute_shared_vpc_host_project.host]
}

resource "google_compute_subnetwork" "default_subnet" {
  name = "${var.slurm_gcp_name}-controller-subnet"
  description = "Primary subnet for the controller"
  ip_cidr_range = "10.10.0.0/16"
  region = var.controller.region
  network = google_compute_network.shared_vpc_network.self_link
}

resource "google_compute_firewall" "default_internal_firewall_rules" {
  name = "${var.slurm_gcp_name}-all-internal"
  network = google_compute_network.shared_vpc_network.self_link
  source_tags = var.slurm_gcp_tags
  target_tags = var.slurm_gcp_tags

  allow {
    protocol = 'tcp'
    ports = [0-65535]
  }
  allow {
    protocol = 'udp'
    ports = [0-65535]
  }
  allow {
    protocol = 'icmp'
    ports = []
  }

}

locals {
  source_ranges = length(var.source_ranges) == 0 ? ["0.0.0.0/0"] : var.source_ranges
}

resource "google_compute_firewall" "default_ssh_firewall_rules" {
  name = "${var.slurm_gcp_name}-ssh"
  network = google_compute_network.shared_vpc_network.self_link
  target_tags = var.slurm_gcp_tags
  source_ranges = local.source_ranges

  allow {
    protocol = 'tcp'
    ports = [22]
  }

}

// Create a list of unique regions from the partitions
locals {
  regions = distinct(flatten([for p in var.partitions : [for m in p.machines : trimsuffix(m.zone,substr(m.zone,-2,-2))]]))
}

// Create any additional shared VPC subnetworks
resource "google_compute_subnetwork" "shared_vpc_subnetworks" {
  count = length(local.regions)
  name = "${var.slurm_gcp_name}-${var.regions[count.index]}"
  ip_cidr_range = cidrsubnet("10.10.0.0/12", 4, count.index) 
  region = local.regions[count.index]
  network = google_compute_network.shared_vpc_network.self_link
}

// *************************************************** //

// TO DO : Construct controller, login, and partitions objects

// Create the Slurm-GCP cluster
module "slurm_gcp" {
  source  = "./terraform-fluidnumerics-slurm_gcp"
  parent_folder = var.parent_folder
  slurm_gcp_admins = var.slurm_gcp_admins
  slurm_gcp_users = var.slurm_gcp_users
  name = var.slurm_gcp_name
  tags = var.slurm_gcp_tags
  controller = var.controller
  login = var.login
  partitions = var.partitions
  slurm_accounts = var.slurm_accounts
}

