###############################
###### Security Groups ########
###############################
# MFA
resource "aws_security_group" "mfa_radius" { # CORE AND TENANT VPC
  name        = "mfa-radius"
  description = "Allow communication to Radius & Workspace"
  vpc_id      = var.private-vpc

  ingress {
    description = "Allow SSH within compartment"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["${var.cidr-range}/24"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["${var.cidr-range}/24"]
  }

  ingress {
    description = "Allow UDP handshake"
    from_port   = 1812
    to_port     = 1812
    protocol    = "UDP"
    cidr_blocks = ["${var.cidr-range}/24"]
  }

  ingress {
    description = "Allow RDS MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["${var.cidr-range}/24"]
  }

  ingress {
    description = "Allow LDAP"
    from_port   = 389
    to_port     = 389
    protocol    = "TCP"
    cidr_blocks = ["${var.cidr-range}/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS
resource "aws_security_group" "rds_db_sg" {
  name        = "rds-db"
  description = "Allow communication between RDS & EC2"
  vpc_id      = var.private-vpc

  ingress {
    description = "Allow SSH within compartment"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["${var.cidr-range}/24"]
  }

  ingress {
    description = "Allow SSH inbound traffic"
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["${var.cidr-range}/24"]
  }

  ingress {
    description = "Allow HTTP inbound traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["${var.cidr-range}/24"]
  }

  ingress {
    description = "Allow HTTPS inbound traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["${var.cidr-range}/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
