# environments/dev/main.tf
# ─────────────────────────────────────────────────────────────────
# Dev environment — orchestrates all modules
# Author: Bremer Quiquia Cirineo
# ─────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in S3 — uncomment after creating the bucket
  # backend "s3" {
  #   bucket = "my-terraform-state-bucket"
  #   key    = "dev/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "BREMERQUIQUIA"
      Repository  = "github.com/BREMERQUIQUIA/terraform-aws-infra"
    }
  }
}

# ── VPC ───────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project             = var.project
  environment         = var.environment
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  common_tags         = local.common_tags
}

# ── EC2 ───────────────────────────────────────────────────────────
module "ec2" {
  source = "../../modules/ec2"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  subnet_id          = module.vpc.public_subnet_id
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.key_name
  ssh_allowed_cidrs  = var.ssh_allowed_cidrs
  root_volume_size   = 20
  assign_eip         = true
  common_tags        = local.common_tags
}

# ── RDS ───────────────────────────────────────────────────────────
module "rds" {
  source = "../../modules/rds"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = [module.vpc.private_subnet_id, module.vpc.public_subnet_id]
  ec2_sg_id          = module.ec2.security_group_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  instance_class     = var.db_instance_class
  common_tags        = local.common_tags
}

# ── S3 ────────────────────────────────────────────────────────────
module "s3" {
  source = "../../modules/s3"

  project     = var.project
  environment = var.environment
  common_tags = local.common_tags
}

# ── Locals ────────────────────────────────────────────────────────
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ── Outputs ───────────────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "ec2_public_ip" {
  description = "EC2 public IP address"
  value       = module.ec2.public_ip
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_name
}
