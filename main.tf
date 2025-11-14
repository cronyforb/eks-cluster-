terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "louis"
  cluster_version = "1.28"

  vpc_id     = "your-vpc-id"  # Replace with your VPC
  subnet_ids = ["subnet-abc123", "subnet-def456"]  # Replace with your subnets

  eks_managed_node_groups = {
    workers = {
      instance_types = ["t3.medium"]
      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}
