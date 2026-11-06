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
}

variable "subnets" {
  description = "Map of subnets configurations"
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    name                    = string
    map_public_ip_on_launch = optional(bool, false)
  }))
  # Validate CIDR format
  validation {
    condition = alltrue([
      for s in values(var.subnets) : can(cidrhost(s.cidr_block, 0))
    ])
    error_message = "All subnets cidr_block values must be valid CIDR blocks (e.g. 10.0.1.0/24)."
  }

  # Validate AZs exist in the current region
  validation {
    condition = alltrue([
      for s in values(var.subnets) : contains(local.available_azs, s.availability_zone)
    ])
    error_message = "One or more subnet availability zones are not valid for this region."
  }
}
