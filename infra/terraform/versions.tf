# Which Terraform and AWS provider versions this code needs.
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws" # official AWS provider
      version = "~> 5.0"        # any 5.x version (no breaking 6.x)
    }
  }
}

# Connect to AWS using the "personal" CLI profile and the chosen region.
provider "aws" {
  region  = var.region
  profile = var.aws_profile

  # Tag every resource we create, so it's easy to find and delete
  default_tags {
    tags = {
      Project   = "apples"
      ManagedBy = "terraform"
    }
  }
}
