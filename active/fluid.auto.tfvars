cluster_name = "oshpc"
primary_project = "os-hackathon-fluid-hpc"
primary_zone = "us-west1-b"

controller_machine_type = "n1-standard-2"
controller_disk_size_gb = 1024
login_machine_type = "n1-standard-2"

partitions = [{name = "n1-8-solo-v100"
               project = ""
               max_time = "8:00:00"
               labels = {"hackathon"="hiphack"}
               machines = [{ name = "n1-8-solo-v100-a"
                             disk_size_gb = 100
                             gpu_count = 1
                             gpu_type = "nvidia-tesla-v100"
                             image = "projects/os-hackathon-fluid-hpc/global/images/fluid-slurm-gcp-compute-os-hack-dev"
                             machine_type = "n1-standard-8"
                             max_node_count = 5
                             preemptible_bursting = false
                             zone = "us-west1-a"
                           },
                           { name = "n1-8-solo-v100-b"
                             disk_size_gb = 100
                             gpu_count = 1
                             gpu_type = "nvidia-tesla-v100"
                             image = "projects/os-hackathon-fluid-hpc/global/images/fluid-slurm-gcp-compute-os-hack-dev"
                             machine_type = "n1-standard-8"
                             max_node_count = 5
                             preemptible_bursting = false
                             zone = "us-west1-b"
                          }
                         ]
              },
              {name = "n1-8-solo-p100"
               project = ""
               max_time = "8:00:00"
               labels = {"hackathon"="hiphack"}
               machines = [{ name = "n1-8-solo-p100-a"
                             disk_size_gb = 100
                             gpu_count = 1
                             gpu_type = "nvidia-tesla-v100"
                             image = "projects/os-hackathon-fluid-hpc/global/images/fluid-slurm-gcp-compute-os-hack-dev"
                             machine_type = "n1-standard-8"
                             max_node_count = 5
                             preemptible_bursting = false
                             zone = "us-west1-a"
                           },
                           { name = "n1-8-solo-p100-b"
                             disk_size_gb = 100
                             gpu_count = 1
                             gpu_type = "nvidia-tesla-v100"
                             image = "projects/os-hackathon-fluid-hpc/global/images/fluid-slurm-gcp-compute-os-hack-dev"
                             machine_type = "n1-standard-8"
                             max_node_count = 5
                             preemptible_bursting = false
                             zone = "us-west1-b"
                          }
                         ]
              },
              {name = "a2-highpu-1g"
               project = ""
               max_time = "8:00:00"
               labels = {"hackathon"="hiphack"}
               machines = [{ name = "a2-1g-a100"
                             disk_size_gb = 100
                             gpu_count = 1
                             gpu_type = "nvidia-tesla-a100"
                             image = "projects/os-hackathon-fluid-hpc/global/images/fluid-slurm-gcp-compute-os-hack-dev"
                             machine_type = "a2-highgpu-1g"
                             max_node_count = 5
                             preemptible_bursting = false
                             zone = "us-central1-a"
                           }
                         ]
              },
              {name = "n2d-standard-224"
               project = ""
               max_time = "8:00:00"
               labels = {"hackathon"="hiphack"}
               machines = [{ name = "n2d-standard-224"
                             disk_size_gb = 30
                             gpu_count = 0
                             gpu_type = ""
                             image = ""
                             machine_type = "n1-standard-8"
                             max_node_count = 2
                             preemptible_bursting = false
                             zone = "us-west1-a"
                           },
                         ]
               },
              {name = "c2-standard-60"
               project = ""
               max_time = "8:00:00"
               labels = {"hackathon"="hiphack"}
               machines = [{ name = "c2-standard-60"
                             disk_size_gb = 30
                             gpu_count = 0
                             gpu_type = ""
                             image = ""
                             machine_type = "c2-standard-60"
                             max_node_count = 5
                             preemptible_bursting = false
                             zone = "us-west1-a"
                           },
                         ]
              },
              {name = "n1-standard-4"
               project = ""
               max_time = "8:00:00"
               labels = {"hackathon"="hiphack"}
               machines = [{ name = "n1-standard-4"
                             disk_size_gb = 30
                             gpu_count = 0
                             gpu_type = ""
                             image = ""
                             machine_type = "n1-standard-4"
                             max_node_count = 10
                             preemptible_bursting = false
                             zone = "us-west1-a"
                           }
                         ]
              },
              {name = "paraview"
               project = ""
               max_time = "8:00:00"
               labels = {"hackathon"="cloud-cfd"}
               machines = [{ name = "paraview"
                             disk_size_gb = 100
                             gpu_count = 0
                             gpu_type = ""
                             image = "projects/fluid-cluster-ops/global/images/paraview-gcp"
                             machine_type = "c2-standard-60"
                             max_node_count = 5
                             preemptible_bursting = false
                             zone = "us-west1-a"
                           }
                         ]
              },
]



slurm_gcp_admins = ["group:support@fluidnumerics.com"]
slurm_gcp_users = ["group:os-hackathon-users@fluidnumerics.cloud"]

slurm_accounts = [{ name = "oshackathon",
                    users = ["joe","alessandro","renault","cory"]
                    allowed_partitions = ["all"]
                  }
]
 
// Settings for CloudSQL as Slurm database
cloudsql_slurmdb = true
cloudsql_name = "oshpc"
cloudsql_tier = "db-n1-standard-1"
