#############
#### RDS ####
#############

##########################
#### MFA RDS instance ####
##########################

data "aws_secretsmanager_secret_version" "mfa-rds-auth" {
  secret_id = "YOUROWN_SECRET_ID"
}

resource "aws_db_subnet_group" "db-sn-group" {
  name        = "rds-subnet-group"
  description = "RDS Subnet Group for VPC"

  subnet_ids = [var.subnet-a, var.subnet-b] # change to id

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "mfa-mysql-instance" {
  identifier = "mfa-db"
  db_name    = "mfa" # Database name
  username   = jsondecode(data.aws_secretsmanager_secret_version.mfa-rds-auth.secret_string)["SQL_username"]
  password   = jsondecode(data.aws_secretsmanager_secret_version.mfa-rds-auth.secret_string)["SQL_password"]

  deletion_protection   = true
  allocated_storage     = 20
  max_allocated_storage = 1000
  engine                = "mysql"
  engine_version        = "8.0.28"
  instance_class        = "db.t3.small"
  storage_encrypted     = true

  backup_retention_period = 7
  skip_final_snapshot     = true
  publicly_accessible     = false

  auto_minor_version_upgrade = true

  vpc_security_group_ids = [aws_security_group.rds_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db-sn-group.name

  iam_database_authentication_enabled = true

  tags = {
    Name = "mfa-db"
  }
}
