variable "customer_folder" {
  type = string
  default = ""
  description = "A GCP folder id (folders/FOLDER-ID) that contains the Fluid-Slurm-GCP controller project and compute partition projects."
}

variable "customer_org_id" {
  type = string
  description = "Customer organization ID from the managed-fluid-slurm-gcp customers database"
}

variable "cloud_sql_tier" {
  type = string
  description = "Instance tier for the Cloud SQL instance that hosts the Slurm database"
  default = "db-f1-micro"
}

variable "home_tier" {
  type = string
  description = "Filestore Tier for the home NFS server. Either STANDARD or PREMIUM"
  default = "STANDARD"
}

variable "home_size_gb" {
  type = number
  description = "Size of the filestore home disk in GB. Minimum : 1024 for STANDARD and 2048 for PREMIUM."
  default = 1024
}

variable "managing_domain" {
  type = string
  description = "The registered GSuite domain used to host Fluid-Slurm-GCP Cloud Identity Accounts"
  default = "fluidnumerics.com"
}

variable "image_version" {
  type = string
  description = "Image version for the fluid-slurm-gcp images"
  default = "v2-4-0"
}

variable "image_flavor" {
  type = string
  description = "Base Fluid-Slurm-GCP image flavor. One of `centos`, `ohpc`, or `ubuntu`"
  default = "centos"
}

variable "primary_project" {
  type = string
  description = "Main GCP project ID for the customer's managed solution"
}

variable "primary_zone" {
  type = string
  description = "Main GCP zone for the customer's managed solution"
}

variable "whitelist_ssh_ips" {
  type = list(string)
  description = "Customer's IP addresses that should be added to a whitelist for ssh access"
  default = ["0.0.0.0/0"]
}

variable "controller_machine_type" { 
  type = string
  description = "GCP Machine type to use for the login node."
}

variable "default_partition" {
  type = string
  description = "Name of the default compute partition."
  default = ""
}

variable "login_machine_type" {
  type = string
  description = "GCP Machine type to use for the login node."
}

variable "partitions" {
  type = list(object({
      name = string
      project = string
      max_time= string
      labels = map(string)
      machines = list(object({
        name = string
        disk_size_gb = number
        disk_type = string
        disable_hyperthreading= bool
        external_ip = bool
        gpu_count = number
        gpu_type = string
        image = string
        n_local_ssds = number
        local_ssd_mount_directory = string
        machine_type=string
        max_node_count= number
        preemptible_bursting= bool
        static_node_count= number
        vpc_subnet = string
        zone= string
      }))
  }))
  description = "Settings for partitions and compute instances available to the cluster."
  
  default = []
}

variable "slurm_accounts" {
  type = list(object({
      name = string
      users = list(string)
      allowed_partitions = list(string)
  }))
  default = []
}

variable "munge_key" {
  type = string
  default = ""
}

variable "suspend_time" {
  type = number
  default = 300
}
