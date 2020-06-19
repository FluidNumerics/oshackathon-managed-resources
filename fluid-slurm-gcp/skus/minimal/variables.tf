variable "customer_folder" {
  type = string
  default = ""
  description = "A GCP folder id (folders/FOLDER-ID) that contains the Fluid-Slurm-GCP controller project and compute partition projects."
}

variable "customer_org_id" {
  type = string
  description = "Customer organization ID from the managed-fluid-slurm-gcp customers database"
}

variable "managing_domain" {
  type = string
  description = "The registered GSuite domain used to host Fluid-Slurm-GCP Cloud Identity Accounts"
  default = "fluidnumerics.com"
}

variable "primary_project" {
  type = string
  description = "Main GCP project ID for the customer's managed solution"
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
      vpc_subnet= string
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
