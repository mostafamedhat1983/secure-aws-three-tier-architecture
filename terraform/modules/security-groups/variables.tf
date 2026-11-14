variable "name" {
  description = "name for the security group"
  type        = string
}

variable "description" {
  description = "description for the security group"
  type        = string
}


variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "security_group_ingress" {
  description = "security group ingress ports"
  type = map(object({
    ip_protocol                  = string
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    referenced_security_group_id = optional(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for s in values(var.security_group_ingress) : s.cidr_ipv4 == null ? true : can(cidrhost(s.cidr_ipv4, 0))
    ])
    error_message = "All ingress cidr_ipv4 values must be valid CIDR blocks (e.g. 10.0.1.0/24)."
  }

  validation {
    condition = alltrue([
      for rule in values(var.security_group_ingress) :
      (rule.cidr_ipv4 != null) != (rule.referenced_security_group_id != null)
    ])
    error_message = "Each ingress rule must set exactly one source: cidr_ipv4 or referenced_security_group_id."
  }
}

variable "security_group_egress" {
  description = "security group egress ports"
  type = map(object({
    ip_protocol                  = string
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    referenced_security_group_id = optional(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for s in values(var.security_group_egress) : s.cidr_ipv4 == null ? true : can(cidrhost(s.cidr_ipv4, 0))
    ])
    error_message = "All egress cidr_ipv4 values must be valid CIDR blocks (e.g. 10.0.1.0/24)."
  }

  validation {
    condition = alltrue([
      for rule in values(var.security_group_egress) :
      (rule.cidr_ipv4 != null) != (rule.referenced_security_group_id != null)
    ])
    error_message = "Each egress rule must set exactly one source: cidr_ipv4 or referenced_security_group_id."
  }

}
