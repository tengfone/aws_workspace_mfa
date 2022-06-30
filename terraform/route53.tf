resource "aws_route53_zone" "route53_url" {
  name = "example.com"
  vpc {
    vpc_id = var.private-vpc
  }
}

# MFA Portal #
resource "aws_route53_record" "route53_mfa_record" {
  zone_id = aws_route53_zone.route53_url.zone_id
  name    = "mfa.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.mfa-alb.dns_name
    zone_id                = aws_lb.mfa-alb.zone_id
    evaluate_target_health = true
  }
}
