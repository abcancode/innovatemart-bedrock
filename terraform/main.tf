# terraform/main.tf

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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Configure providers
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "InnovateMart-Bedrock"
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  project_name    = var.project_name
  environment     = var.environment
  cluster_version = var.cluster_version
  
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_max_size      = var.node_max_size
  node_min_size      = var.node_min_size
}

# RDS Module for managed databases
module "rds" {
  source = "./modules/rds"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  # Security group from EKS for database access
  eks_security_group_id = module.eks.cluster_security_group_id
}

# IAM Module for developer access
module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
  
  cluster_name = module.eks.cluster_name
  cluster_arn  = module.eks.cluster_arn
}

# Configure Kubernetes and Helm providers after EKS cluster is created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region,
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region,
      ]
    }
  }
}

# Install AWS Load Balancer Controller
#resource "helm_release" "aws_load_balancer_controller" {
#  depends_on = [module.eks]
  
#  name       = "aws-load-balancer-controller"
#  repository = "https://aws.github.io/eks-charts"
#  chart      = "aws-load-balancer-controller"
#  namespace  = "kube-system"
#  version    = "1.6.2"

#  set {
#    name  = "clusterName"
#    value = module.eks.cluster_name
#  }

#  set {
#    name  = "serviceAccount.create"
#    value = "true"
#  }

#  set {
#    name  = "serviceAccount.name"
#    value = "aws-load-balancer-controller"
# }

#  set {
#    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#    value = module.eks.aws_load_balancer_controller_role_arn
#  }

#  set {
#    name  = "region"
#    value = var.aws_region
#  }

#  set {
#    name  = "vpcId"
#    value = module.vpc.vpc_id
#  }
#}

# Create secrets for database connections (will be used in Phase 2)
#resource "kubernetes_secret" "db_secrets" {
#  depends_on = [module.eks, module.rds]
  
#  metadata {
#    name      = "db-secrets"
#    namespace = "default"
#  }

#  data = {
    # PostgreSQL (Orders service)
#    POSTGRES_HOST     = module.rds.postgres_endpoint
#    POSTGRES_DB       = module.rds.postgres_database
#    POSTGRES_USER     = module.rds.postgres_username
#    POSTGRES_PASSWORD = module.rds.postgres_password
    
    # MySQL (Catalog service)  
#    MYSQL_HOST     = module.rds.mysql_endpoint
#    MYSQL_DATABASE = module.rds.mysql_database
#    MYSQL_USER     = module.rds.mysql_username
#    MYSQL_PASSWORD = module.rds.mysql_password
    
    # DynamoDB (Carts service)
#    DYNAMODB_TABLE_NAME = module.rds.dynamodb_table_name
#    AWS_REGION          = var.aws_region
#  }

#  type = "Opaque"
# }