# ==============================================================================
# SecureVault - three-tier architecture on AWS (root module)
# ==============================================================================
# This file only CALLS the modules and connects them. The provider and the S3
# state backend are already defined in provider.tf and backend.tf.
#
# Traffic path - these are the ONLY ports open between layers:
#
#   Internet  --443 HTTPS-->  Public ALB
#   Public ALB            --8080-->  Frontend instances
#   Frontend instances    --80-->    Internal ALB
#   Internal ALB          --5000-->  Backend instances
#   Backend instances     --3306 (TLS)-->  RDS MySQL
#   Frontend + backend    --443-->   AWS APIs through the NAT gateway
#                                    (SSM, ECR, Secrets Manager, package repos)
#
# No SSH anywhere: instances have no public IP and no port 22 is open.
# Use SSM Session Manager to get a shell.
#
# Created MANUALLY before the first apply (outside Terraform):
#   1. S3 bucket for the Terraform state (backend.tf)
#   2. ECR repositories, with both images already pushed
#   3. S3 bucket for ALB access logs, with a bucket policy for the log delivery
#   4. ACM certificate for vault.mostafa-medhat.online in us-east-2
# ==============================================================================

locals {
  # Fixed settings for this portfolio deployment. Change these values here;
  # child modules still receive their own inputs through module arguments.
  config = {
    project                        = "securevault"
    vpc_cidr_block                 = "10.0.0.0/16"
    allowed_ingress_cidrs          = ["0.0.0.0/0"]
    certificate_arn                = "arn:aws:acm:us-east-2:079239504201:certificate/541c5bc9-e5df-44a8-8a6f-8cc337ee312c"
    ssl_policy                     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    enable_deletion_protection     = false
    alb_access_logs_bucket         = "depi-alb-logs"
    frontend_ecr_repository_name   = "vault-frontend"
    backend_ecr_repository_name    = "vault-backend"
    frontend_image_tag             = "1.0.0"
    backend_image_tag              = "1.0.0"
    ami_id                         = "ami-01e4a7224fcbfe81f"
    instance_type                  = "t3.micro"
    asg_min_size                   = 2
    asg_desired_capacity           = 2
    asg_max_size                   = 4
    app_secret_name                = "vault/app"
    secret_recovery_window_in_days = 7
    db_name                        = "vaultdb"
    db_engine_version              = "8.4"
    db_parameter_group_family      = "mysql8.4"
    db_instance_class              = "db.t3.micro"
    db_multi_az                    = true
    db_backup_retention_period     = 1
    db_skip_final_snapshot         = true
    db_apply_immediately           = true
  }
}

# ------------------------------------------------------------------------------
# 1. Lookups (read-only, nothing is created here)
# ------------------------------------------------------------------------------
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# The ECR repositories are created by hand, so we look them up by name
data "aws_ecr_repository" "frontend" {
  name = local.config.frontend_ecr_repository_name
}

data "aws_ecr_repository" "backend" {
  name = local.config.backend_ecr_repository_name
}

# ------------------------------------------------------------------------------
# 2. Locals (values computed once and reused below)
# ------------------------------------------------------------------------------
locals {
  region = data.aws_region.current.region

  # Two Availability Zones: every layer is spread over both (ALB and RDS need two)
  az_a = data.aws_availability_zones.available.names[0]
  az_b = data.aws_availability_zones.available.names[1]

  # Public traffic is HTTPS only.
  public_listener_port = 443

  # Container images pulled from ECR by the instances at boot
  ecr_registry   = split("/", data.aws_ecr_repository.backend.repository_url)[0]
  frontend_image = "${data.aws_ecr_repository.frontend.repository_url}:${local.config.frontend_image_tag}"
  backend_image  = "${data.aws_ecr_repository.backend.repository_url}:${local.config.backend_image_tag}"

  # The networking module groups subnets by type (public/private/data), but the
  # frontend and the backend are both "private". We pick them by key instead.
  frontend_subnet_ids = [
    module.networking.subnet_ids["frontend-a"],
    module.networking.subnet_ids["frontend-b"],
  ]
  backend_subnet_ids = [
    module.networking.subnet_ids["backend-a"],
    module.networking.subnet_ids["backend-b"],
  ]
}

# ------------------------------------------------------------------------------
# 3. Networking: VPC, 8 subnets, internet gateway, regional NAT, route tables
# ------------------------------------------------------------------------------
# Subnet layout (/24 blocks cut from the VPC range, shown for 10.0.0.0/16):
#   public   10.0.0.0/24   10.0.1.0/24    -> internet-facing ALB
#   frontend 10.0.10.0/24  10.0.11.0/24   -> frontend instances (private)
#   backend  10.0.20.0/24  10.0.21.0/24   -> internal ALB + backend instances (private)
#   data     10.0.30.0/24  10.0.31.0/24   -> RDS (no route to the internet at all)
module "networking" {
  source = "./modules/networking"

  vpc_cidr_block = local.config.vpc_cidr_block
  vpc_name       = "${local.config.project}-vpc"

  # Both are needed for the private DNS zone and for resolving the RDS endpoint
  enable_dns_support   = true
  enable_dns_hostnames = true

  route_table_name = local.config.project
  # The VPC default security group is locked down (no rules = deny all)
  default_sg_name = "${local.config.project}-default-sg-locked"

  subnets = {
    "public-a" = {
      name              = "${local.config.project}-public-a"
      cidr_block        = cidrsubnet(local.config.vpc_cidr_block, 8, 0)
      availability_zone = local.az_a
      type              = "public"
    }
    "public-b" = {
      name              = "${local.config.project}-public-b"
      cidr_block        = cidrsubnet(local.config.vpc_cidr_block, 8, 1)
      availability_zone = local.az_b
      type              = "public"
    }
    "frontend-a" = {
      name              = "${local.config.project}-frontend-a"
      cidr_block        = cidrsubnet(local.config.vpc_cidr_block, 8, 10)
      availability_zone = local.az_a
      type              = "private"
    }
    "frontend-b" = {
      name              = "${local.config.project}-frontend-b"
      cidr_block        = cidrsubnet(local.config.vpc_cidr_block, 8, 11)
      availability_zone = local.az_b
      type              = "private"
    }
    "backend-a" = {
      name              = "${local.config.project}-backend-a"
      cidr_block        = cidrsubnet(local.config.vpc_cidr_block, 8, 20)
      availability_zone = local.az_a
      type              = "private"
    }
    "backend-b" = {
      name              = "${local.config.project}-backend-b"
      cidr_block        = cidrsubnet(local.config.vpc_cidr_block, 8, 21)
      availability_zone = local.az_b
      type              = "private"
    }
    "data-a" = {
      name              = "${local.config.project}-data-a"
      cidr_block        = cidrsubnet(local.config.vpc_cidr_block, 8, 30)
      availability_zone = local.az_a
      type              = "data"
    }
    "data-b" = {
      name              = "${local.config.project}-data-b"
      cidr_block        = cidrsubnet(local.config.vpc_cidr_block, 8, 31)
      availability_zone = local.az_b
      type              = "data"
    }
  }
}

# ------------------------------------------------------------------------------
# 4. Security groups: one per layer, each accepts traffic ONLY from the layer above
# ------------------------------------------------------------------------------
# Rules point at other security groups (not IP ranges), so only the exact
# neighbour can connect. Rule keys describe the rule, so they never need renaming.
# Security groups are stateful: replies to allowed traffic need no extra rule.

# Public ALB: the only thing reachable from the internet
module "sg_alb" {
  source = "./modules/security-groups"

  name        = "${local.config.project}-public-alb"
  description = "Public ALB: accepts users and talks only to the frontend"
  vpc_id      = module.networking.vpc_id

  # One rule per allowed source range (the whole internet by default)
  security_group_ingress = {
    for cidr in local.config.allowed_ingress_cidrs :
    "tcp-${local.public_listener_port}-from-${cidr}" => {
      ip_protocol = "tcp"
      from_port   = local.public_listener_port
      to_port     = local.public_listener_port
      cidr_ipv4   = cidr
      description = "Users to the public ALB"
    }
  }

  security_group_egress = {
    "tcp-8080-to-frontend" = {
      ip_protocol                  = "tcp"
      from_port                    = 8080
      to_port                      = 8080
      referenced_security_group_id = module.sg_frontend.security_group_id
      description                  = "Public ALB to the frontend"
    }
  }
}

# Frontend instances
module "sg_frontend" {
  source = "./modules/security-groups"

  name        = "${local.config.project}-frontend"
  description = "Frontend: accepts only the public ALB and talks to the internal ALB"
  vpc_id      = module.networking.vpc_id

  security_group_ingress = {
    "tcp-8080-from-public-alb" = {
      ip_protocol                  = "tcp"
      from_port                    = 8080
      to_port                      = 8080
      referenced_security_group_id = module.sg_alb.security_group_id
      description                  = "Public ALB to the frontend"
    }
  }

  security_group_egress = {
    "tcp-80-to-internal-alb" = {
      ip_protocol                  = "tcp"
      from_port                    = 80
      to_port                      = 80
      referenced_security_group_id = module.sg_internal_alb.security_group_id
      description                  = "Frontend to the internal ALB"
    }
    "tcp-443-to-aws-apis" = {
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTPS to SSM, ECR and package repos through the NAT gateway"
    }
  }
}

# Internal ALB: sits between the frontend and the backend, never reachable from the internet
module "sg_internal_alb" {
  source = "./modules/security-groups"

  name        = "${local.config.project}-internal-alb"
  description = "Internal ALB: accepts only the frontend and talks to the backend"
  vpc_id      = module.networking.vpc_id

  security_group_ingress = {
    "tcp-80-from-frontend" = {
      ip_protocol                  = "tcp"
      from_port                    = 80
      to_port                      = 80
      referenced_security_group_id = module.sg_frontend.security_group_id
      description                  = "Frontend to the internal ALB"
    }
  }

  security_group_egress = {
    "tcp-5000-to-backend" = {
      ip_protocol                  = "tcp"
      from_port                    = 5000
      to_port                      = 5000
      referenced_security_group_id = module.sg_backend.security_group_id
      description                  = "Internal ALB to the backend"
    }
  }
}

# Backend instances
module "sg_backend" {
  source = "./modules/security-groups"

  name        = "${local.config.project}-backend"
  description = "Backend: accepts only the internal ALB and talks to the database"
  vpc_id      = module.networking.vpc_id

  security_group_ingress = {
    "tcp-5000-from-internal-alb" = {
      ip_protocol                  = "tcp"
      from_port                    = 5000
      to_port                      = 5000
      referenced_security_group_id = module.sg_internal_alb.security_group_id
      description                  = "Internal ALB to the backend"
    }
  }

  security_group_egress = {
    "tcp-3306-to-database" = {
      ip_protocol                  = "tcp"
      from_port                    = 3306
      to_port                      = 3306
      referenced_security_group_id = module.sg_db.security_group_id
      description                  = "Backend to MySQL"
    }
    "tcp-443-to-aws-apis" = {
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTPS to Secrets Manager, SSM and ECR through the NAT gateway"
    }
  }
}

# Database: only the backend may connect, and it never starts any connection itself
module "sg_db" {
  source = "./modules/security-groups"

  name        = "${local.config.project}-db"
  description = "Database: accepts only the backend"
  vpc_id      = module.networking.vpc_id

  security_group_ingress = {
    "tcp-3306-from-backend" = {
      ip_protocol                  = "tcp"
      from_port                    = 3306
      to_port                      = 3306
      referenced_security_group_id = module.sg_backend.security_group_id
      description                  = "Backend to MySQL"
    }
  }

  # No egress rules on purpose: the database needs no outbound access
}

# ------------------------------------------------------------------------------
# 5. IAM: one role per tier, least privilege
# ------------------------------------------------------------------------------
# Both roles get SSM (shell without SSH) and permission to pull ONLY their own
# image. Only the backend role may read secrets, and only the two it needs.
module "iam_frontend" {
  source = "./modules/iam"

  name                = "${local.config.project}-frontend"
  ecr_repository_arns = [data.aws_ecr_repository.frontend.arn]
  secret_arns         = [] # the frontend can not read any secret
}

module "iam_backend" {
  source = "./modules/iam"

  name                = "${local.config.project}-backend"
  ecr_repository_arns = [data.aws_ecr_repository.backend.arn]
  secret_arns = [
    module.rds.master_secret_arn,
    module.secrets_manager.secret_arn,
  ]
}

# ------------------------------------------------------------------------------
# 6. Secrets Manager: the app keys (fernet_key and session_key), generated by Terraform
# ------------------------------------------------------------------------------
# The database password is NOT here: RDS creates and manages its own secret.
module "secrets_manager" {
  source = "./modules/secrets-manager"

  secret_name             = local.config.app_secret_name
  recovery_window_in_days = local.config.secret_recovery_window_in_days
}

# ------------------------------------------------------------------------------
# 7. RDS MySQL: private data subnets, encrypted, TLS required, managed password
# ------------------------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  identifier = "${local.config.project}-db"
  rds_name   = "${local.config.project}-db"

  engine         = "mysql"
  engine_version = local.config.db_engine_version
  instance_class = local.config.db_instance_class
  db_name        = local.config.db_name # the app expects this exact name
  username       = "admin"              # the password is generated and stored by RDS in Secrets Manager

  allocated_storage = 20
  storage_type      = "gp3"
  multi_az          = local.config.db_multi_az

  # Network: only the two data subnets, only the database security group
  subnet_group_name  = "${local.config.project}-db-subnets"
  subnet_ids         = module.networking.data_subnet_ids
  security_group_ids = [module.sg_db.security_group_id]

  # require_secure_transport = 1 is set inside the module's parameter group
  db_parameter_group_name_prefix = "${local.config.project}-db-"
  db_parameter_group_family      = local.config.db_parameter_group_family

  backup_retention_period    = local.config.db_backup_retention_period
  maintenance_window         = "sun:03:00-sun:04:00"
  auto_minor_version_upgrade = true
  apply_immediately          = local.config.db_apply_immediately
  skip_final_snapshot        = local.config.db_skip_final_snapshot

  cloudwatch_log_group_error_name     = "${local.config.project}-rds-error-logs"
  cloudwatch_log_group_slowquery_name = "${local.config.project}-rds-slowquery-logs"
}

# ------------------------------------------------------------------------------
# 8. Load balancers: one public (users), one internal (frontend -> backend)
# ------------------------------------------------------------------------------
module "alb_public" {
  source = "./modules/alb"

  name     = "${local.config.project}-public-alb"
  internal = false
  vpc_id   = module.networking.vpc_id

  subnet_ids                 = module.networking.public_subnet_ids
  security_group_ids         = [module.sg_alb.security_group_id]
  enable_deletion_protection = local.config.enable_deletion_protection

  # Access logs go to the existing bucket; its policy must allow ALB log delivery.
  access_logs_bucket = local.config.alb_access_logs_bucket
  access_logs_prefix = "public-alb"

  # HTTPS only. The ACM certificate must exist in us-east-2 before apply.
  listener_port     = 443
  listener_protocol = "HTTPS"
  certificate_arn   = local.config.certificate_arn
  ssl_policy        = local.config.ssl_policy

  # Frontend instances listen on 8080 and answer /healthz
  target_group_name_prefix = "fe-"
  target_group_port        = 8080
  health_check_path        = "/healthz"

  # The internet-facing ALB needs the internet gateway attached first
  depends_on = [module.networking]
}

module "alb_internal" {
  source = "./modules/alb"

  name     = "${local.config.project}-internal-alb"
  internal = true
  vpc_id   = module.networking.vpc_id

  subnet_ids                 = local.backend_subnet_ids
  security_group_ids         = [module.sg_internal_alb.security_group_id]
  enable_deletion_protection = local.config.enable_deletion_protection

  access_logs_bucket = local.config.alb_access_logs_bucket
  access_logs_prefix = "internal-alb"

  # Plain HTTP, but only inside the private subnets and only from the frontend
  listener_port     = 80
  listener_protocol = "HTTP"

  # Backend instances listen on 5000 and answer /api/health
  target_group_name_prefix = "be-"
  target_group_port        = 5000
  health_check_path        = "/api/health"
}



# ========================================
# Private Route 53 Hosted Zone
# ========================================

module "route53_private_zone" {
  source = "./modules/route53-private-zone"

  zone_name   = "vault.internal"
  record_name = "backend.vault.internal"

  # Associate the private hosted zone with the project VPC.
  vpc_id = module.networking.vpc_id

  # Point the private DNS record to the internal ALB.
  alb_dns_name = module.alb_internal.dns_name
  alb_zone_id  = module.alb_internal.zone_id
}


# ------------------------------------------------------------------------------
# 10. Auto Scaling Groups: the EC2 instances that run the containers
# ------------------------------------------------------------------------------
# Instances have no public IP, IMDSv2 is required, the root volume is encrypted.
# The boot scripts install Docker, log in to ECR and start the hardened container
# (read-only filesystem, all capabilities dropped, no privilege escalation).
# depends_on makes sure the NAT gateway and routes exist before instances boot,
# because the boot script needs the internet to install Docker and reach ECR.
module "asg_backend" {
  source = "./modules/asg"

  name                  = "${local.config.project}-backend"
  ami_id                = local.config.ami_id
  instance_type         = local.config.instance_type
  instance_profile_name = module.iam_backend.instance_profile_name
  security_group_ids    = [module.sg_backend.security_group_id]
  subnet_ids            = local.backend_subnet_ids
  target_group_arn      = module.alb_internal.target_group_arn

  # Hop limit 2 allows the backend container to reach the instance role
  # through IMDSv2 so it can read its two Secrets Manager values.
  metadata_hop_limit = 2

  min_size         = local.config.asg_min_size
  max_size         = local.config.asg_max_size
  desired_capacity = local.config.asg_desired_capacity

  user_data = templatefile("${path.module}/templates/backend_user_data.sh.tftpl", {
    region         = local.region
    registry       = local.ecr_registry
    image          = local.backend_image
    db_host        = module.rds.address
    db_name        = local.config.db_name
    db_secret_arn  = module.rds.master_secret_arn
    app_secret_arn = module.secrets_manager.secret_arn
    cookie_secure  = true # Secure cookies only make sense over HTTPS
  })

  depends_on = [module.networking]
}

module "asg_frontend" {
  source = "./modules/asg"

  name                  = "${local.config.project}-frontend"
  ami_id                = local.config.ami_id
  instance_type         = local.config.instance_type
  instance_profile_name = module.iam_frontend.instance_profile_name
  security_group_ids    = [module.sg_frontend.security_group_id]
  subnet_ids            = local.frontend_subnet_ids
  target_group_arn      = module.alb_public.target_group_arn

  # Hop limit 1: the frontend container never calls AWS APIs
  metadata_hop_limit = 1

  min_size         = local.config.asg_min_size
  max_size         = local.config.asg_max_size
  desired_capacity = local.config.asg_desired_capacity

  user_data = templatefile("${path.module}/templates/frontend_user_data.sh.tftpl", {
    registry = local.ecr_registry
    region   = local.region
    image    = local.frontend_image
  })

  depends_on = [module.networking]
}

# ------------------------------------------------------------------------------
# 11. WAF: AWS managed rule groups in front of the public ALB
# ------------------------------------------------------------------------------
module "waf" {
  source = "./modules/waf"

  name        = "${local.config.project}-waf"
  description = "AWS managed rule groups for the public ALB"
  metric_name = "${local.config.project}-waf"
  alb_arn     = module.alb_public.alb_arn
}
