# Copyright 2021 Fluid Numerics LLC
#
#  Modified for use with multi-regional setup, CloudSQL, FileStore, and Lustre.
#
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  backend "gcs" {
    bucket  = "os-hackathon-fluid-hpc-tf-states"
    prefix  = "slurm-gcp"
  }
}

provider "google" {
  project = var.project
  region  = local.region
}

locals {
  compute_admins = flatten(["serviceAccount:${google_service_account.slurm_controller.email}",var.slurm_gcp_admins])
  cloudsql_admins = flatten(["serviceAccount:${google_service_account.slurm_controller.email}",var.slurm_gcp_admins])
  storage_admins = flatten(["serviceAccount:${google_service_account.slurm_compute.email}","serviceAccount:${google_service_account.slurm_login.email}",var.slurm_gcp_admins])
  oslogin = var.slurm_gcp_users
  oslogin_admins = var.slurm_gcp_admins
  service_account_users = flatten([var.slurm_gcp_users,var.slurm_gcp_admins,"serviceAccount:${google_service_account.slurm_controller.email}"])
  region = join("-", slice(split("-", var.zone), 0, 2))
}


// Service Accounts //
resource "google_service_account" "slurm_controller" {
  account_id = "slurm-gcp-controller"
  display_name = "Slurm-GCP Controller Service Account"
  project = var.project
}

resource "google_service_account" "slurm_compute" {
  account_id = "slurm-gcp-compute"
  display_name = "Slurm-GCP Compute Service Account"
  project = var.project
}

resource "google_service_account" "slurm_login" {
  account_id = "slurm-gcp-login"
  display_name = "Slurm-GCP Login Service Account"
  project = var.project
}

// ***************************************** //
// Set IAM policies

resource "google_project_iam_member" "project_compute_admins" {
  count = length(local.compute_admins)
  project = var.project
  role = "roles/compute.admin"
  member = local.compute_admins[count.index]
}

resource "google_project_iam_member" "project_cloudsql_admins" {
  count = length(local.cloudsql_admins)
  project = var.project
  role = "roles/cloudsql.admin"
  member = local.cloudsql_admins[count.index]
}

resource "google_project_iam_member" "project_storage_admins" {
  count = length(local.storage_admins)
  project = var.project
  role = "roles/storage.admin"
  member = local.storage_admins[count.index]
}

resource "google_project_iam_member" "project_oslogin" {
  count = length(local.oslogin)
  project = var.project
  role = "roles/compute.osLogin"
  member = local.oslogin[count.index]
}

resource "google_project_iam_member" "project_oslogin_admin" {
  count = length(local.oslogin_admins)
  project = var.project
  role    = "roles/compute.osAdminLogin"
  member = local.oslogin_admins[count.index]
}

resource "google_project_iam_member" "project_service_account_users" {
  count = length(local.service_account_users)
  project = var.project
  role = "roles/iam.serviceAccountUser"
  member = local.service_account_users[count.index]
}

resource "google_project_iam_member" "project_compute_image_users" {
  count = length(local.service_account_users)
  project = var.project
  role = "roles/compute.imageUser"
  member = "serviceAccount:${google_service_account.slurm_controller.email}"
}

// Create the Shared VPC Network
resource "google_compute_network" "shared_vpc_network" {
  name = "${var.cluster_name}-shared-network"
  project = var.project
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default_subnet" {
  name = "${var.cluster_name}-controller-subnet"
  description = "Primary subnet for the controller"
  ip_cidr_range = var.subnet_cidr
  region = local.region
  network = google_compute_network.shared_vpc_network.self_link
  project = var.project
}

resource "google_compute_firewall" "default_internal_firewall_rules" {
  name = "${var.cluster_name}-all-internal"
  network = google_compute_network.shared_vpc_network.self_link
  source_tags = [var.cluster_name]
  target_tags = [var.cluster_name]
  project = var.project

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
  name = "${var.cluster_name}-ssh"
  network = google_compute_network.shared_vpc_network.self_link
  target_tags = [var.cluster_name]
  source_ranges = var.whitelist_ssh_ips
  project = var.project

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
}

// Create a list of unique regions from the partitions
locals {
  regions = distinct([for p in var.partitions : trimsuffix(p.zone,substr(p.zone,-2,-2))])
  flatRegions = [for p in var.partitions : trimsuffix(p.zone,substr(p.zone,-2,-2))]
  flatZones = [for p in var.partitions : p.zone]
  regionToZone = zipmap(local.flatRegions,local.flatZones)
}

// Create any additional shared VPC subnetworks
resource "google_compute_subnetwork" "shared_vpc_subnetworks" {
  count = length(local.regions)
  name = "${var.cluster_name}-${local.regions[count.index]}"
  ip_cidr_range = cidrsubnet("10.10.0.0/8", 8, count.index+11)
  region = local.regions[count.index]
  network = google_compute_network.shared_vpc_network.self_link
  project = var.project
}

// Create a map that takes in zone and returns subnet (for partition creation)
locals {
  zoneToSubnet = {for s in google_compute_subnetwork.shared_vpc_subnetworks : local.regionToZone[s.region] => s.self_link}
  zoneToSubnetName = {for s in google_compute_subnetwork.shared_vpc_subnetworks : local.regionToZone[s.region] => s.name}
}

// Create partitions with dynamically assigned subnets (multi-region support) //
locals {
  partitions = [for p in var.partitions : { name                 = p.name
                                            machine_type         = p.machine_type
                                            image                = p.image
                                            image_hyperthreads   = p.image_hyperthreads
                                            static_node_count    = 0
                                            max_node_count       = p.max_node_count
                                            zone                 = p.zone
                                            compute_disk_type    = p.compute_disk_type
                                            compute_disk_size_gb = p.compute_disk_size_gb
                                            compute_labels       = p.compute_labels
                                            cpu_platform         = p.cpu_platform
                                            gpu_count            = p.gpu_count
                                            gpu_type             = p.gpu_type
                                            network_storage      = p.network_storage
                                            preemptible_bursting = p.preemptible_bursting
                                            vpc_subnet           = local.zoneToSubnet[p.zone]
                                            exclusive            = p.exclusive
                                            enable_placement     = p.enable_placement
                                            regional_capacity    = p.regional_capacity
                                            regional_policy      = p.regional_policy
                                            instance_template    = p.instance_template
                                          }
              ]
}

// ***************************************** //
// Create the Cloud SQL instance

resource "google_compute_global_address" "private_ip_address" {
  count = var.cloudsql_slurmdb ? 1 : 0
  provider = google-beta
  name = "private-ip-address"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16
  network = google_compute_network.shared_vpc_network.self_link
  project = var.project
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.cloudsql_slurmdb ? 1 : 0
  provider = google-beta
  network = google_compute_network.shared_vpc_network.self_link
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

resource "google_sql_database_instance" "slurm_db" {
  count = var.cloudsql_slurmdb ? 1 : 0
  provider = google-beta
  name = var.cloudsql_name
  database_version = "MYSQL_5_6"
  region = local.region
  project = var.project
  depends_on = [google_service_networking_connection.private_vpc_connection[0]]

  settings {
    tier = var.cloudsql_tier
    ip_configuration {
      ipv4_enabled  = var.cloudsql_enable_ipv4
      private_network = google_compute_network.shared_vpc_network.self_link
    }
  }
//  deletion_protection = false
}

resource "google_sql_user" "slurm" {
  count = var.cloudsql_slurmdb ? 1 : 0
  name = "slurm"
  instance = google_sql_database_instance.slurm_db[0].name
  password = "changeme"
}

locals {
  cloudsql = var.cloudsql_slurmdb ? {"db_name":google_sql_database_instance.slurm_db[0].name, 
                                     "server_ip":google_sql_database_instance.slurm_db[0].private_ip_address,
                                     "user": "slurm",
                                     "password": "changeme"} : null
}
// ***************************************** //

module "slurm_cluster_controller" {
  source = "github.com/FluidNumerics/slurm-gcp//tf/modules/controller"

  boot_disk_size                = var.controller_disk_size_gb
  boot_disk_type                = var.controller_disk_type
  cluster_name                  = var.cluster_name
  cloudsql                      = local.cloudsql
  compute_node_scopes           = var.compute_node_scopes
  compute_node_service_account  = var.compute_node_service_account
  disable_compute_public_ips    = var.disable_compute_public_ips
  disable_controller_public_ips = var.disable_controller_public_ips
  image                         = var.controller_image
  labels                        = var.controller_labels
  login_network_storage         = var.login_network_storage
  login_node_count              = var.login_node_count
  machine_type                  = var.controller_machine_type
  munge_key                     = var.munge_key
  network_storage               = var.network_storage
  partitions                    = local.partitions
  project                       = var.project
  region                        = local.region
  secondary_disk                = var.controller_secondary_disk
  secondary_disk_size           = var.controller_secondary_disk_size
  secondary_disk_type           = var.controller_secondary_disk_type
  shared_vpc_host_project       = var.shared_vpc_host_project
  scopes                        = var.controller_scopes
  service_account               = google_service_account.slurm_controller.email
  subnet_depend                 = local.zoneToSubnet[var.zone]
  subnetwork_name               = local.zoneToSubnetName[var.zone]
  suspend_time                  = var.suspend_time
  zone                          = var.zone
}

module "slurm_cluster_login" {
  source = "github.com/FluidNumerics/slurm-gcp//tf/modules/login"

  boot_disk_size            = var.login_disk_size_gb
  boot_disk_type            = var.login_disk_type
  cluster_name              = var.cluster_name
  controller_name           = module.slurm_cluster_controller.controller_node_name
  controller_secondary_disk = var.controller_secondary_disk
  disable_login_public_ips  = var.disable_login_public_ips
  labels                    = var.login_labels
  login_network_storage     = var.login_network_storage
  image                     = var.login_image
  machine_type              = var.login_machine_type
  node_count                = var.login_node_count
  region                    = local.region
  scopes                    = var.login_node_scopes
  service_account           = google_service_account.slurm_login.email
  munge_key                 = var.munge_key
  network_storage           = var.network_storage
  shared_vpc_host_project   = var.shared_vpc_host_project
  subnet_depend             = local.zoneToSubnet[var.zone]
  subnetwork_name           = local.zoneToSubnetName[var.zone]
  zone                      = var.zone
}
