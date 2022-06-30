
# MFA role
# EC2 service role for MFA
data "aws_iam_policy_document" "mfa_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mfa-radius-role" {
  name               = "mfa-radius-role"
  assume_role_policy = data.aws_iam_policy_document.mfa_policy.json
}

resource "aws_iam_instance_profile" "mfa-radius-instance-profile" {
  name = "mfa-radius-role"
  role = aws_iam_role.mfa-radius-role.name
}

resource "aws_iam_role_policy_attachment" "mfa-radius-instance-rds-role" {
  role       = aws_iam_role.mfa-radius-role.name
  policy_arn = aws_iam_policy.service_rds_rw.arn
}

resource "aws_iam_role_policy_attachment" "mfa-radius-instance-cloudwatch-role" {
  role       = aws_iam_role.mfa-radius-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "mfa-radius-instance-ssm-role" {
  role       = aws_iam_role.mfa-radius-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "mfa-radius-instance-ssm-automation-role" {
  role       = aws_iam_role.mfa-radius-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

resource "aws_iam_policy" "service_rds_rw" {
  name        = "mfa-rds-permissions"
  path        = "/"
  description = "To be attached to Service roles that need read/write only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:*"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:rds:us-east-1:${var.aws-account}:db:mfa-db"
        ]
      },
    ]
  })
}
