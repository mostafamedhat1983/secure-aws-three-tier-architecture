output "address" {
  description = "Hostname of the database (the DB_HOST value)."
  value       = aws_db_instance.this.address
}

output "master_secret_arn" {
  description = "ARN of the Secrets Manager secret that RDS created for the master password."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
