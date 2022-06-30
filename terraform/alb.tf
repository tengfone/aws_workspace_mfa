#############################
# Application Load Balancer #
#############################

data "aws_acm_certificate" "ssl_cert" {
  domain   = "*.example.com"
  statuses = ["ISSUED"]
}

##########################
###### MFA Portal #######
##########################

resource "aws_lb_target_group" "mfa-target-group" {
  name        = "mfa-portal"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = var.private-vpc
}

resource "aws_lb_target_group_attachment" "mfa-target-group-attachement" {
  target_group_arn = aws_lb_target_group.mfa-target-group.arn
  target_id        = aws_instance.mfa-portal-ec2.id
  port             = 443
}

resource "aws_lb" "mfa-alb" {
  name               = "mfa-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mfa_radius.id]

  enable_deletion_protection = true

  drop_invalid_header_fields = true

  subnet_mapping {
    subnet_id = var.subnet-a
  }

  subnet_mapping {
    subnet_id = var.subnet-b
  }

  subnet_mapping {
    subnet_id = var.subnet-c
  }
}

resource "aws_lb_listener" "mfa-alb-listener" {
  load_balancer_arn = aws_lb.mfa-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.ssl_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mfa-target-group.arn
  }
}

resource "aws_lb_listener" "redirect_user_http_to_https" {
  load_balancer_arn = aws_lb.mfa-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
