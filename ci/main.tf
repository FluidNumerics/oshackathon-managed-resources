terraform {
  backend "gcs" {
    bucket  = "os-hackathon-fluid-hpc-tf-states"
    prefix  = "ci"
  }
}

provider "google" {
}

resource "google_cloudbuild_trigger" "cluster_prod" {
  name = ""
  project = var.project
  description = "Deploy/Update production cluster"
  github {
    owner = "FluidNumerics"
    name = "oshackathon-managed-resources"
    push {
      branch = "cluster/prod"
    }
  }
  filename = "tf/prod/cloudbuild.yaml"
}

resource "google_cloudbuild_trigger" "cluster_dev" {
  name = ""
  project = var.project
  description = "Create a terraform plan for a production cluster"
  github {
    owner = "FluidNumerics"
    name = "oshackathon-managed-resources"
    push {
      branch = "cluster/dev"
    }
  }
  filename = "tf/dev/cloudbuild.yaml"
}

resource "google_cloudbuild_trigger" "img_prod" {
  name = ""
  project = var.project
  description = "Create and test a new production VM image"
  github {
    owner = "FluidNumerics"
    name = "oshackathon-managed-resources"
    push {
      branch = "img/prod"
    }
  }
  substitutions = {
    _ZONE = "us-central1-c"
    _SUBNETWORK = "default"
    _SOURCE_IMAGE_FAMILY = "fluid-slurm-gcp-centos-7-v3"
    _SOURCE_IMAGE_PROJECT = "fluid-cluster-ops"
    _IMAGE_FAMILY = "oshackathon-slurm-gcp"
    _INSTALL_ROOT = "/opt"
    _SLURM_ROOT = "/usr/local"
  }
  filename = "img/cloudbuild.yaml"
}

resource "google_cloudbuild_trigger" "img_dev" {
  name = ""
  project = var.project
  description = "Create and test a new dev VM image"
  github {
    owner = "FluidNumerics"
    name = "oshackathon-managed-resources"
    push {
      branch = "img/dev"
    }
  }
  substitutions = {
    _ZONE = "us-central1-c"
    _SUBNETWORK = "default"
    _SOURCE_IMAGE_FAMILY = "fluid-slurm-gcp-centos-7-v3"
    _SOURCE_IMAGE_PROJECT = "fluid-cluster-ops"
    _IMAGE_FAMILY = "oshackathon-slurm-gcp-dev"
    _INSTALL_ROOT = "/opt"
    _SLURM_ROOT = "/usr/local"
  }
  filename = "img/cloudbuild.yaml"
}
