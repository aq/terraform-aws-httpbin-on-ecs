terraform {
  required_version = "~> 0.14.3"

  required_providers {
    aws = {
      version = "~> 3.22.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# This is Paris region.
variable "aws_region" {
  default = "eu-west-3"
}
