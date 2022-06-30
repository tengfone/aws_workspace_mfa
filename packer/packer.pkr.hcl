packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "centos" {
  ami_name           = "centos-mfa-radius-ami-${local.timestamp}"
  instance_type      = "t2.micro"
  region             = "us-east-1"
  ssh_interface      = "public_ip"
  subnet_id          = var.subnet_id
  security_group_ids = var.security_group_ids
  ssh_timeout        = "5m"
  user_data_file     = "./user_data.sh"
  ami_description    = "CentOS 7 for MFA on Workspace. Uses Radius + PrivacyIDEA"
  tags = {
    Name = "centos-mfa-radius-ami-${local.timestamp}"
  }
  source_ami_filter {
    filters = {
      name                = "CENTOSxxxx" # replace it yourself
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["Amazon"]
  }
  ssh_username   = "centos"
  ssh_agent_auth = false
}

build {
  name = "packer-build-mfa"
  sources = [
    "source.amazon-ebs.centos"
  ]
  provisioner "shell" {
    script          = "./startup.sh"
    execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'" # To run script as sudo
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet of an internet VPC"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security Group of the packer instance"
}
