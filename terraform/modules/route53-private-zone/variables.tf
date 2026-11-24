
# ========================================
# Hosted Zone Configuration
# ========================================

variable "zone_name" {
  description = "Name of the private hosted zone."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC associated with the private hosted zone."
  type        = string
}

# ========================================
# DNS Record Configuration
# ========================================

variable "record_name" {
  description = "DNS name of the backend record."
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the internal ALB."
  type        = string
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the internal ALB."
  type        = string
}
