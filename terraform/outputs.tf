# Outputs needed after Terraform creates the infrastructure.

output "application_url" {
  description = "Public application URL (create the Namecheap CNAME after apply)."
  value       = "https://vault.mostafa-medhat.online"
}

output "public_alb_dns_name" {
  description = "Create a CNAME for vault.mostafa-medhat.online pointing to this DNS name."
  value       = module.alb_public.dns_name
}

output "internal_alb_dns_name" {
  description = "Private AWS-generated DNS name used by the frontend container."
  value       = module.alb_internal.dns_name
}

output "frontend_image_build_command" {
  description = "Build the frontend with the internal ALB DNS name after the first apply."
  value       = "docker build --build-arg BACKEND_URL=http://${module.alb_internal.dns_name} --build-arg DNS_RESOLVER=${cidrhost(local.config.vpc_cidr_block, 2)} -t ${local.frontend_image} ./frontend"
}

output "frontend_image" {
  description = "Frontend image reference used by the frontend Auto Scaling Group."
  value       = local.frontend_image
}

output "backend_image" {
  description = "Backend image reference used by the backend Auto Scaling Group."
  value       = local.backend_image
}

output "rds_address" {
  description = "Private RDS endpoint hostname."
  value       = module.rds.address
}

output "rds_master_secret_arn" {
  description = "ARN of the RDS-managed master credentials secret."
  value       = module.rds.master_secret_arn
}

output "app_secret_arn" {
  description = "ARN of the application encryption/session keys secret."
  value       = module.secrets_manager.secret_arn
}

output "vpc_id" {
  description = "ID of the project VPC."
  value       = module.networking.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs indexed by the keys defined in the networking module call."
  value       = module.networking.subnet_ids
}

output "security_group_ids" {
  description = "Security group IDs for each application tier."
  value = {
    public_alb   = module.sg_alb.security_group_id
    frontend     = module.sg_frontend.security_group_id
    internal_alb = module.sg_internal_alb.security_group_id
    backend      = module.sg_backend.security_group_id
    database     = module.sg_db.security_group_id
  }
}

output "asg_names" {
  description = "Auto Scaling Group names for the frontend and backend tiers."
  value = {
    frontend = module.asg_frontend.asg_name
    backend  = module.asg_backend.asg_name
  }
}

output "waf_web_acl_arn" {
  description = "ARN of the Web ACL associated with the public ALB."
  value       = module.waf.web_acl_arn
}
