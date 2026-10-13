terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region              = "ap-south-1"
  allowed_account_ids = ["425034746374"]

  default_tags {
    tags = {
      Project   = "login-lab"
      ManagedBy = "Terraform"
    }
  }
}