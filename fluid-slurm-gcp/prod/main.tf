

// Configure the Google Cloud provider
provider "google" {
 version = "3.9"
}


locals {
  fs_zone = {for each fs in var.filestore : fs.name => fs.zone}
  fs_tier = {for each fs in var.filestore : fs.name => fs.tier}
  fs_project = {for each fs in var.filestore : fs.name => fs.project}
  fs_capacity_gb = {for each fs in var.filestore : fs.name => fs.capacity_gb}
  fs_network = {for each fs in var.filestore : fs.name => fs.network}
  fs_mount = {for each fs in var.filestore : fs.name => fs.mount}
  fs_share = {for each fs in var.filestore : fs.name => fs.share}
}
// Create the filestore instance
resource "google_filestore_instance" "file_server" {
  for_each = local.fs_zone 
  name = each.key
  zone = each.value
  tier = local.fs_tier[each.key]
  project = local.fs_project[each.key]

  file_shares {
    capacity_gb = local.fs_capacity_gb[each.key]
    name        = local.fs_share[each.key]
  }

  networks {
    network = local.fs_network[each.key]
    modes   = ["MODE_IPV4"]
  }
}

// Set up the mounts metadata
locals {
  server_directory = {for fs in google_filestore_instance.file_server : fs.name => "${fs.networks[0].ip_addresses[0]}:/${fs.file_shares[0].name}"}
}

locals {
  mounts = [for fs in google_filestore_instace.file_server : {
              group = "root",
              mount_directory = local.fs_mount[fs.name],
              mount_options = "rw,hard,intr",
              owner = "root",
              protocol = "nfs"
              permission = "755"
              server_directory = local.server_directory[fs.name]
             }
           ]
}

// Create the Slurm-GCP cluster
module "slurm_gcp" {
  source  = "app.terraform.io/fluidnumerics/slurm_gcp/fluidnumerics"
  version = "1.0.9"
  parent_folder = var.parent_folder
  slurm_gcp_admins = var.slurm_gcp_admins
  slurm_gcp_users = var.slurm_gcp_users
  name = var.slurm_gcp_name
  tags = var.slurm_gcp_tags
  controller = var.controller
  login = var.login
  mounts = local.mounts
  partitions = var.partitions
  slurm_accounts = var.slurm_accounts
}
