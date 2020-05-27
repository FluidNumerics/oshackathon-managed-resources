terraform {
  backend "gcs" {
    bucket  = "managed-fluid-slurm-gcp-customer-tfstates"
    prefix  = "TEMPLATE/fluid-slurm-gcp/prod"
  }
}
