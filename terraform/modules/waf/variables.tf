
variable "name" {
  description = "Name of the WAF Web ACL"
  type        = string
}

variable "description" {
  description = "Description of the WAF Web ACL"
  type        = string
}

variable "metric_name" {
  description = "CloudWatch metric name for the Web ACL"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the public Application Load Balancer"
  type        = string
}
