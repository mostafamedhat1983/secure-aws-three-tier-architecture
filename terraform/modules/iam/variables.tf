variable "name" {
  description = "name for the iam role"
  type        = string
}

variable "ecr_repository_arns" {
  description = "ECR repositories this role will pull images from."
  type        = list(string)
}

variable "secret_arns" {
  description = "Secrets Manager secrets this role may read. Leave empty for no secret access."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for a in var.secret_arns : startswith(a, "arn:aws:secretsmanager:")])
    error_message = "Every entry must be a Secrets Manager ARN."
  }
}
