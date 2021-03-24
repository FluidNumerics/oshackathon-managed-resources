cluster_name = "@ORG@"
primary_project = "@PROJECT ID@"
primary_zone = "@ZONE@"

controller_machine_type = "n1-standard-8"
login_machine_type = "n1-standard-8"

partitions = [{name = "demo"
               project = ""
               max_time = "8:00:00"
               labels = {"slurm-gcp"="compute"}
               machines = [{ name = "demo"
                             disk_size_gb = 30
                             gpu_count = 0
                             gpu_type = ""
                             image = ""
                             machine_type = "n1-standard-32"
                             max_node_count = 5
                             preemptible_bursting = false
                             zone = "@ZONE@"
                          }]
               }
]



slurm_gcp_admins = ["group:@ORG@-admins@example.com"]
slurm_gcp_users = ["user:@ORG@-users@example.com"]

slurm_accounts = [{ name = "demo-account",
                    users = ["somebody"]
                    allowed_partitions = ["demo"]
                 }]
 
// Settings for CloudSQL as Slurm database
//cloudsql_slurmdb = true
//cloudsql_name = "slurmdb"
//cloudsql_tier = "db-n1-standard-8"
