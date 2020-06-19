
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
