#!/bin/bash

cwd = $(pwd)

cd terraform-fluidnumerics-gcp_iam && git checkout tags/v0.0.3 -b v0.0.3
cd ../terraform-fluidnumerics-gcp_shared_networking && git checkout tags/v0.0.8 -b v0.0.8
