data "aws_ami" "aml_harden_ami" {
  owners      = [var.aws-account]
  most_recent = true

  filter {
    name   = "name"
    values = ["centos-mfa-radius-ami-*"] # Note, run packer first to get AMI
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

###########################
####### MFA Portal ########
###########################
locals {
  ec2_mfa_portal_name = "mfa-portal"
}


resource "aws_network_interface" "network_interface_user_portal" {
  subnet_id       = var.subnet-a
  security_groups = [aws_security_group.mfa_radius.id]
  private_ips     = [var.mfa-static-ip]
}

resource "aws_instance" "mfa-portal-ec2" {
  ami                                  = data.aws_ami.aml_harden_ami.id
  instance_type                        = "t2.medium"
  iam_instance_profile                 = aws_iam_instance_profile.mfa-radius-instance-profile.name
  disable_api_termination              = true
  instance_initiated_shutdown_behavior = "stop"

  network_interface {
    network_interface_id = aws_network_interface.network_interface_user_portal.id
    device_index         = 0
  }

  # root disk
  root_block_device {
    volume_size           = "8"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${local.ec2_mfa_portal_name}"
  }
}
