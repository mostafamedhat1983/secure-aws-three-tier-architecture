variable "name" {
  description = "Base name for the launch template, Auto Scaling Group and tags (for example vault-backend)"
  type        = string
}

variable "ami_id" {
  description = "Pinned AMI ID."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (x86, for example t3.micro)"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name from the iam module"
  type        = string
}

variable "security_group_ids" {
  description = "Security groups for the instances"
  type        = list(string)
}

variable "metadata_hop_limit" {
  description = "Instance metadata hop limit (2 for the backend, 1 for the frontend)"
  type        = number
}

variable "root_volume_size" {
  description = "Root volume size in GiB"
  type        = number
  default     = 8
}

variable "user_data" {
  description = "Boot script, rendered with templatefile() in the root module"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets where the instances run"
  type        = list(string)
}

variable "target_group_arn" {
  description = "Target group from the alb module that receives the instances"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "desired_capacity" {
  description = "Number of instances to start with"
  type        = number
}

variable "health_check_grace_period" {
  description = "Seconds to wait before health checks can replace a new instance"
  type        = number
  default     = 300
}

variable "cpu_target_value" {
  description = "Average CPU percentage the scaling policy tries to keep"
  type        = number
  default     = 50
}
