terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    rafay = {
      source = "RafaySystems/rafay"
      version = "1.1.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.region
  shared_credentials_file = var.aws_credentials_file
}

provider "rafay" {
  provider_config_file = var.rafay_config_file
}