###################
#### Variables ####
###################

# generic vars
variable "aws-account" {
  type = string
}

# VPC vars
variable "private-vpc" {
  type = string
}

variable "cidr-range" {
  type = string
}

# MFA Instance IP
variable "mfa-static-ip" {
  type = string
}

# Subnet vars
variable "subnet-a" {
  type = string
}

variable "subnet-b" {
  type = string
}

variable "subnet-c" {
  type = string
}
