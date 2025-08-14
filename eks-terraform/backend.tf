terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 5.25.0"
    }
  }
    backend "s3" {
    bucket = "stiti5671-terraform-state"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}
