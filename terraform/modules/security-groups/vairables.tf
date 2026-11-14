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

variable "security-group-ingress" {
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
      for rule in values(var.security-group-ingress) :
      (rule.cidr_ipv4 != null) != (rule.referenced_security_group_id != null)
    ])
    error_message = "Each ingress rule must set exactly one source: cidr_ipv4 or referenced_security_group_id."
  }
}

variable "security-group-egress" {
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
      for rule in values(var.security-group-egress) :
      (rule.cidr_ipv4 != null) != (rule.referenced_security_group_id != null)
    ])
    error_message = "Each egress rule must set exactly one source: cidr_ipv4 or referenced_security_group_id."
  }

}
