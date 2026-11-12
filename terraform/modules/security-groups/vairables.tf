variable "name" {
  description = "name for the security group"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "security-group-ingress" {
  description = "security group ingress ports"
  type = map(object({
    ip_protocol = string
    from_port   = number
    to_port     = number
    cidr_ipv4   = string
  }))
}

variable "security-group-egress" {
  description = "security group egress ports"
  type = map(object({
    ip_protocol = string
    from_port   = number
    to_port     = number
    cidr_ipv4   = string
  }))
}
