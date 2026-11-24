
# ========================================
# Private Route 53 Hosted Zone
# ========================================

resource "aws_route53_zone" "this" {
  name = var.zone_name

  # Associate the private hosted zone with the existing VPC.
  vpc {
    vpc_id = var.vpc_id
  }

  comment = "Private DNS zone for SecureVault"
}

# ========================================
# Internal ALB DNS Record
# ========================================

resource "aws_route53_record" "backend" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.record_name
  type    = "A"

  # Route traffic to the internal ALB using an AWS alias record.
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
