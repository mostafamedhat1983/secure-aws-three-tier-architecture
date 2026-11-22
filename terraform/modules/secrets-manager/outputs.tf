output "secret_arn" {
  description = "ARN of the secret (used by the backend IAM policy and APP_SECRET_ARN)"
  value       = aws_secretsmanager_secret.this.arn

  # The keys must be stored before anything that reads this output starts (the backend instances).
  depends_on = [aws_secretsmanager_secret_version.this]
}

output "secret_name" {
  description = "Name of the secret"
  value       = aws_secretsmanager_secret.this.name
}
