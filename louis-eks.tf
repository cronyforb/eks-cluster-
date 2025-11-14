terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "louis-eks"
      Terraform   = "true"
    }
  }
}

# Create VPC for EKS
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "louis-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "louis"
  cluster_version = "1.28"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group
  eks_managed_node_groups = {
    workers = {
      name           = "worker-group"
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 20

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Remote access (optional)
      # remote_access = {
      #   ec2_ssh_key = "your-key-name"
      #   source_security_group_ids = [aws_security_group.remote_access.id]
      # }

      tags = {
        NodeGroup = "workers"
      }
    }
  }

  # Cluster security group additional rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Node security group additional rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Data source for EKS cluster auth
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token

  # Only after cluster is created
  depends_on = [module.eks]
}

# Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ids attached to the EKS node groups"
  value       = module.eks.node_security_group_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "kubectl_command" {
  description = "kubectl config command"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}"
}

output "test_nodes" {
  description = "Command to test node connectivity"
  value       = "kubectl get nodes"
}
