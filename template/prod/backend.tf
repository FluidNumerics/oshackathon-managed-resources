terraform {
  backend "gcs" {
    bucket  = "managed-fluid-slurm-gcp-customer-tfstates"
    prefix  = "TEMPLATE/prod"
  }
}
