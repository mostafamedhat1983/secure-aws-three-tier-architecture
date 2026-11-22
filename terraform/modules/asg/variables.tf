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

  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be zero or greater."
  }

}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number

  validation {
    condition     = var.max_size >= 1
    error_message = "max_size must be at least 1."
  }

}

variable "desired_capacity" {
  description = "Number of instances to start with"
  type        = number

  validation {
    condition     = var.desired_capacity >= 0
    error_message = "desired_capacity must be zero or greater."
  }
}

variable "health_check_grace_period" {
  description = "Minimum time after launch before the ASG can replace an instance due to a failed health check.Gives the application time to start and become ready."
  type        = number
  default     = 300
}

variable "default_instance_warmup" {
  description = "Time after launch during which a new instance's CloudWatch metrics are excluded from scaling decisions.Prevents startup CPU/memory spikes from triggering unnecessary scale-out actions."
  type        = number
  default     = 300
}


variable "cpu_target_value" {
  description = "Average CPU percentage the scaling policy tries to keep"
  type        = number
  default     = 50

  validation {
    condition = (
      var.cpu_target_value > 0 &&
      var.cpu_target_value <= 100
    )

    error_message = "cpu_target_value must be greater than 0 and no more than 100."
  }
}
