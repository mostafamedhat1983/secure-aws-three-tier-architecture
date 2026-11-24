
# ========================================
# Private Hosted Zone Outputs
# ========================================

output "private_zone_id" {
  description = "ID of the private Route 53 hosted zone."
  value       = aws_route53_zone.this.zone_id
}

output "backend_dns_name" {
  description = "Private DNS name pointing to the internal ALB."
  value       = aws_route53_record.backend.fqdn
}
