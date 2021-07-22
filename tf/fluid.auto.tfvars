cluster_name = "ocean"
project = "os-hackathon-fluid-hpc"
zone = "us-west1-b"
cloudsql_slurmdb = true

slurm_gcp_admins = ["group:support@fluidnumerics.com"]
slurm_gcp_users = ["user:joe@fluidnumerics.com"]

partitions = [
  { name                 = "c2"
    machine_type         = "c2-standard-60"
    image                = "projects/os-hackathon-fluid-hpc/global/images/family/oshackathon-slurm-gcp"
    image_hyperthreads   = true
    static_node_count    = 0
    max_node_count       = 10
    zone                 = "us-west1-b"
    compute_disk_type    = "pd-standard"
    compute_disk_size_gb = 50
    compute_labels       = {}
    cpu_platform         = null
    gpu_count            = 0
    gpu_type             = null
    network_storage      = []
    preemptible_bursting = false
    vpc_subnet           = null
    exclusive            = false
    enable_placement     = false
    regional_capacity    = false
    regional_policy      = null
    instance_template    = null
  },
  { name                 = "v100"
    machine_type         = "n1-custom-12-9216"
    image                = "projects/os-hackathon-fluid-hpc/global/images/family/oshackathon-slurm-gcp"
    image_hyperthreads   = true
    static_node_count    = 0
    max_node_count       = 10
    zone                 = "us-west1-b"
    compute_disk_type    = "pd-standard"
    compute_disk_size_gb = 50
    compute_labels       = {}
    cpu_platform         = null
    gpu_count            = 1
    gpu_type             = "nvidia-tesla-v100"
    network_storage      = []
    preemptible_bursting = false
    vpc_subnet           = null
    exclusive            = false
    enable_placement     = false
    regional_capacity    = false
    regional_policy      = null
    instance_template    = null
  },
  { name                 = "p100"
    machine_type         = "n1-custom-12-9216"
    image                = "projects/os-hackathon-fluid-hpc/global/images/family/oshackathon-slurm-gcp"
    image_hyperthreads   = true
    static_node_count    = 0
    max_node_count       = 10
    zone                 = "us-west1-b"
    compute_disk_type    = "pd-standard"
    compute_disk_size_gb = 50
    compute_labels       = {}
    cpu_platform         = null
    gpu_count            = 1
    gpu_type             = "nvidia-tesla-p100"
    network_storage      = []
    preemptible_bursting = false
    vpc_subnet           = null
    exclusive            = false
    enable_placement     = false
    regional_capacity    = false
    regional_policy      = null
    instance_template    = null
  }
]

disable_controller_public_ips = true
disable_login_public_ips      = false
disable_compute_public_ips    = true


controller_image = "projects/os-hackathon-fluid-hpc/global/images/family/oshackathon-slurm-gcp"
controller_machine_type = "n1-standard-8"
controller_disk_size_gb = 1024
login_machine_type = "n1-standard-8"
login_image = "projects/os-hackathon-fluid-hpc/global/images/family/oshackathon-slurm-gcp"

compute_node_scopes          = [
  "https://www.googleapis.com/auth/cloud-platform"
]

suspend_time  = 300
