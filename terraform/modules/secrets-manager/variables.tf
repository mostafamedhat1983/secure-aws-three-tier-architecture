variable "secret_name" {
  description = "Name of the secret in Secrets Manager (for example vault/app)"
  type        = string
}

variable "description" {
  description = "What the secret is for"
  type        = string
  default     = "SecureVault application keys (fernet_key and session_key)"
}

variable "recovery_window_in_days" {
  description = "Days a deleted secret stays recoverable (0 deletes it immediately, otherwise 7 to 30)"
  type        = number

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "Use 0, or a number from 7 to 30."
  }

}
