# ========================================
# Terraform & Provider Configuration
# ========================================
# AWS provider v6.71.0 pinned for stability

terraform {
  required_version = "v1.17.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.71.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "DEPI"
    }
  }
}