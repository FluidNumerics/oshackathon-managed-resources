#!/bin/bash

ORG=$(grep customer_org_id active/fluid.auto.tfvars | awk -F " = " '{print $2}' | sed 's/"//g')
ZONE=$(grep primary_zone active/fluid.auto.tfvars | awk -F " = " '{print $2}' | sed 's/"//g')

# Force a clean stop of the instances
gcloud compute instances stop ${ORG}-slurm-controller --zone=$ZONE
gcloud compute instances stop ${ORG}-slurm-login-0 --zone=$ZONE

# Start the instances
gcloud compute instances start ${ORG}-slurm-controller --zone=$ZONE
gcloud compute instances start ${ORG}-slurm-login-0 --zone=$ZONE
