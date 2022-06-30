#! /bin/bash

terraform init -reconfigure -var-file=var.tfvars
terraform apply -var-file=var.tfvars
