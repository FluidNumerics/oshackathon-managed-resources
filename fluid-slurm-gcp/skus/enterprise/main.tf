
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

resource "google_filestore_instance" "home_server" {
  name = "${var.slurm_gcp_name}-home-fs"
  zone = var.controller.zone
  tier = var.home_tier
  project = var.controller.project

  file_shares {
    capacity_gb = var.home_size_gb
    name        = 'home'
  }

  networks {
    network = var.vpc_network 
    modes   = ["MODE_IPV4"]
  }
}

resource "google_filestore_instance" "share_server" {
  count = var.share_size_gb == 0 ? 0 : 1
  name = "${var.slurm_gcp_name}-share-fs"
  zone = var.controller.zone
  tier = var.share_tier
  project = var.controller.project

  file_shares {
    capacity_gb = var.share_size_gb
    name        = 'share'
  }

  networks {
    network = var.vpc_network 
    modes   = ["MODE_IPV4"]
  }
}

locals {
  share_mount = var.share_size_gb == 0 ? {} : {
                                                group = "root",
                                                mount_directory = "/mnt/share",
                                                mount_options = "rw,hard,intr",
                                                owner = "root",
                                                protocol = "nfs"
                                                permission = "755"
                                                server_directory = "${google_filestore_instance.share_server.networks[0].ip_addresses[0]}:${google_filestore_instance.share_server.file_shares[0].name}"
                                               }
  home_mount = {
                 group = "root",
                 mount_directory = "/home",
                 mount_options = "rw,hard,intr",
                 owner = "root",
                 protocol = "nfs"
                 permission = "755"
                 server_directory = "${google_filestore_instance.home_server.networks[0].ip_addresses[0]}:${google_filestore_instance.home_server.file_shares[0].name}"
               }
}

locals {
  mounts = [home_mount, share_mount]
}


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
  mounts = local.mounts
  partitions = var.partitions
  slurm_accounts = var.slurm_accounts
}
