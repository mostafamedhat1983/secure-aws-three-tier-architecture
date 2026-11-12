output "role_arn" {
  description = "ARN of the IAM role."
  value       = aws_iam_role.this.arn
}

output "instance_profile_name" {
  description = "Instance profile name for the launch template."
  value       = aws_iam_instance_profile.this.name
}
