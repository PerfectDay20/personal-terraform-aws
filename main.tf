terraform {
  required_version = ">=1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-perfectday20"
    dynamodb_table = "terraform_locks_table"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    profile        = "personal"
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "personal"
}

