variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string

  # Validates CIDR format by attempting to calculate the first IP; can() catches errors if invalid
  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "Must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "microservices-platform"
}