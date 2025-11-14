terraform {
  required_version = ">= 0.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.76.0"  # Much older, smaller version
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
