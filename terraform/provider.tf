
terraform {
  required_version = "1.17.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.71.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
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
