
terraform {
  backend "gcs" {
    bucket  = "managed-fluid-slurm-gcp-customer-tfstates"
    prefix  = "fn-0000000001/fluid-slurm-gcp"
  }
}

// Configure the Google Cloud provider
provider "google" {
 version = "3.9"
}


// Enable necessary API's
resource "google_project_service" "compute" {
  project = var.primary_project
  service = "compute.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "iam" {
  project = var.primary_project
  service = "iam.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "monitoring" {
  project = var.primary_project
  service = "monitoring.googleapis.com"
  disable_dependent_services = true
}

locals {
  primary_region = trimsuffix(var.primary_zone,substr(var.primary_zone,-2,-2))
  slurm_gcp_admins = ["group:${var.customer_org_id}-slurm-gcp-admins@${var.managing_domain}"]
  slurm_gcp_users = ["group:${var.customer_org_id}-slurm-gcp-users@${var.managing_domain}"]
  slurm_gcp_name = "${var.customer_org_id}-slurm"
}

// Mark the Controller project as the Shared VPC Host Project
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.primary_project
  depends_on = [google_project_service.compute,google_project_service.iam]
}

// Obtain a unique list of projects from the partitions, excluding the host project
locals {
  projects = distinct([for p in var.partitions : p.project if p.project != var.primary_project])
}

// Mark the Shared VPC Service Projects
resource "google_compute_shared_vpc_service_project" "service" {
  count = length(local.projects)
  host_project = var.primary_project
  service_project = local.projects[count.index]
  depends_on = [google_compute_shared_vpc_host_project.host]
}

// Create the Shared VPC Network
resource "google_compute_network" "shared_vpc_network" {
  name = "${local.slurm_gcp_name}-shared-network"
  project = var.primary_project
  auto_create_subnetworks = false
  depends_on = [google_compute_shared_vpc_host_project.host]
}

resource "google_compute_subnetwork" "default_subnet" {
  name = "${local.slurm_gcp_name}-controller-subnet"
  description = "Primary subnet for the controller"
  ip_cidr_range = "10.10.0.0/16"
  region = local.primary_region
  network = google_compute_network.shared_vpc_network.self_link
  project = var.primary_project
}

resource "google_compute_firewall" "default_internal_firewall_rules" {
  name = "${local.slurm_gcp_name}-all-internal"
  network = google_compute_network.shared_vpc_network.self_link
  source_tags = [local.slurm_gcp_name]
  target_tags = [local.slurm_gcp_name]
  project = var.primary_project

  allow {
    protocol = "tcp"
    ports = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports = ["0-65535"]
  }
  allow {
    protocol = "icmp"
    ports = []
  }

}


resource "google_compute_firewall" "default_ssh_firewall_rules" {
  name = "${local.slurm_gcp_name}-ssh"
  network = google_compute_network.shared_vpc_network.self_link
  target_tags = [local.slurm_gcp_name]
  source_ranges = var.whitelist_ssh_ips
  project = var.primary_project

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

}

// Create a list of unique regions from the partitions
locals {
  regions = distinct(flatten([for p in var.partitions : [for m in p.machines : trimsuffix(m.zone,substr(m.zone,-2,-2))]]))
}

// Create any additional shared VPC subnetworks
resource "google_compute_subnetwork" "shared_vpc_subnetworks" {
  count = length(local.regions)
  name = "${local.slurm_gcp_name}-${local.regions[count.index]}"
  ip_cidr_range = cidrsubnet("10.11.0.0/12", 4, count.index) 
  region = local.regions[count.index]
  network = google_compute_network.shared_vpc_network.self_link
}

// *************************************************** //

locals {
  controller_image = "projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-controller-${var.image_flavor}-${var.image_version}"
  login_image = "projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-login-${var.image_flavor}-${var.image_version}"
  compute_image = "projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-compute-${var.image_flavor}-${var.image_version}"

  controller = {
    machine_type = var.controller_machine_type
    disk_size_gb = 1024
    disk_type = "pd-standard"
    labels = {"slurm-gcp"="controller"}
    project = var.primary_project
    region = local.primary_region
    vpc_subnet = google_compute_subnetwork.default_subnet.self_link
    zone = var.primary_zone
  }
  login = [{
    machine_type = var.login_machine_type
    disk_size_gb = 15
    disk_type = "pd-standard"
    labels = {"slurm-gcp"="login"}
    project = var.primary_project
    region = local.primary_region
    vpc_subnet = google_compute_subnetwork.default_subnet.self_link
    zone = var.primary_zone
  }]
  
  partitions = length(var.partitions) != 0 ? var.partitions : [{ name = "basic"
                                                                 project = var.primary_project
                                                                 max_time = "8:00:00"
                                                                 labels = {"slurm-gcp"="compute"}
                                                                 machines = [{ name = "basic"
                                                                               disk_size_gb = 15
                                                                               disk_type = "pd-standard"
                                                                               disable_hyperthreading = false
                                                                               external_ip = false
                                                                               gpu_count = 0
                                                                               gpu_type = ""
                                                                               n_local_ssds = 0
                                                                               image = local.compute_image
                                                                               local_ssd_mount_directory = "/scratch"
                                                                               machine_type = "n1-standard-16"
                                                                               max_node_count = 5
                                                                               preemptible_bursting = false
                                                                               static_node_count = 0
                                                                               vpc_subnet = google_compute_subnetwork.default_subnet.self_link
                                                                               zone = var.primary_zone
                                                                            }]
                                                              }]



}



// Create the Slurm-GCP cluster
module "slurm_gcp" {
  source  = "/workspace/terraform-fluidnumerics-slurm_gcp"
  controller_image = local.controller_image
  compute_image = local.compute_image
  login_image = local.login_image
  parent_folder = "folders/${var.customer_folder}"
  slurm_gcp_admins = local.slurm_gcp_admins
  slurm_gcp_users = local.slurm_gcp_users
  name = local.slurm_gcp_name
  tags = [local.slurm_gcp_name]
  controller = local.controller
  login = local.login
  partitions = local.partitions
  slurm_accounts = var.slurm_accounts
}

