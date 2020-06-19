variable "parent_folder" {
  type = string
  default = ""
  description = "A GCP folder id (folders/FOLDER-ID) that contains the Fluid-Slurm-GCP controller project and compute partition projects."
}

variable "slurm_gcp_admins" {
  type = list(string)
  description = "List of users or groups to provide slurm-gcp admin role"
}

variable "slurm_gcp_users" {
  type = list(string)
  description = "List of users or groups to provide slurm-gcp user role"
}

variable "slurm_gcp_name" {
  type = string
}

variable "slurm_gcp_tags" { 
  type = list(string)
  default = []
}

variable "controller" { 
  type = object({
      machine_type = string
      disk_size_gb = number
      disk_type = string
      labels = map(string)
      project = string
      region = string
      vpc_subnet = string
      zone = string
  })
}

variable "default_partition" {
  type = string
  description = "Name of the default compute partition."
  default = "default"
}

variable "login" {
  type= list(object({
      machine_type = string
      disk_size_gb = number
      disk_type = string
      labels = map(string)
      project = string
      region = string
      vpc_subnet = string
      zone = string
  }))
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
