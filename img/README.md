# OS Hackathon : Slurm-GCP VM Image
Copyright 2021 Fluid Numerics LLC

Maintainers: @schoonovernumerics


This directory contains the necessary scripts for building the VM image for OS Hackathon's Slurm-GCP cluster. It consists of the following assetts

* `cloudbuild.yaml` : [Google Cloud Build](https://cloud.google.com/build) build script, used to control steps to bake VM image on GCP.
* `packer.json`: [Hashicorp Packer](https://packer.io) script to specify steps necessary to bake VM image
* `etc/` : Customizations for OS `/etc/` directory. This directory is specified to be copied in during image baking in `packer.json`.
* `install.sh` : Installation script for installing packages specified in `env/spack.yaml`
* `env/spack.yaml` : Spack environment file for installing packages (e.g. Singularity and EasyBuild)


