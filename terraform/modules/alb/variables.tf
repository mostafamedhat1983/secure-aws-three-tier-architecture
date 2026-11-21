variable "name" {
  description = "Name of the load balancer, also used for tags"
  type        = string
}

variable "internal" {
  description = "false for an internet-facing ALB, true for an internal ALB"
  type        = bool
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the load balancer (public subnets for the public ALB, app subnets for the internal ALB)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs must be provided."
  }
}

variable "security_group_ids" {
  description = "Security groups for the load balancer"
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Block deletion of the load balancer (keep false for short-lived test stacks)"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket that receives the access logs (must already exist and allow log delivery)"
  type        = string
}

variable "access_logs_prefix" {
  description = "Folder inside the log bucket for this ALB (must be public-alb or internal-alb to match the names in s3 bucket policy)"
  type        = string

  validation {
    condition     = contains(["public-alb", "internal-alb"], var.access_logs_prefix)
    error_message = "access logs folder name must be public-alb or internal-alb."
  }
}

variable "listener_port" {
  description = "Port the listener accepts connections on (443 or 80)"
  type        = number
}

variable "listener_protocol" {
  description = "Listener protocol (HTTPS or HTTP)"
  type        = string

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.listener_protocol)
    error_message = "listener_protocol must be HTTP or HTTPS (uppercase)."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN, only for an HTTPS listener"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "TLS security policy name, only for an HTTPS listener"
  type        = string
  default     = null
}

variable "target_group_name_prefix" {
  description = "Name prefix for the target group (short, check the provider docs for the maximum length)"
  type        = string
}

variable "target_group_port" {
  description = "Port the instances listen on (8080 for the frontend, 5000 for the backend)"
  type        = number
}

variable "health_check_path" {
  description = "Path used for health checks (/healthz for the frontend, /api/health for the backend)"
  type        = string
}
