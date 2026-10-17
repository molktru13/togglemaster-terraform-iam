terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ToggleMaster"
      Environment = "production"
      Phase       = "Fase-03"
      ManagedBy   = "Terraform-Bootstrap"
    }
  }
}

variable "aws_region" {
  description = "Região da AWS para o bucket de estado remoto"
  type        = string
  default     = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "togglemaster-tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  description = "Nome do Bucket S3 criado para o Backend Remoto do Terraform"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN do Bucket S3 de estado remoto"
  value       = aws_s3_bucket.terraform_state.arn
}
