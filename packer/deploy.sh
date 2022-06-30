#!/bin/bash

packer init .
packer build --var-file=variables.pkrvars.hcl packer.pkr.hcl
