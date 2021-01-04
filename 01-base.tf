terraform {
  required_version = ">= 0.14.3, < 0.15.0"

  required_providers {
    aws = {
      version = ">= 3.22.0, < 4.0.0"
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

variable "cidr_blocks" {
  default = {
    vpc       = "192.168.1.0/29"
    private_1 = "192.168.1.0/30"
    private_2 = "192.168.1.4/30"
  }
}

variable "availability_zones" {
  type    = list
  default = ["e", "f"] # the first ones are historicaly the first of AWS. Now sometimes, they are full.
}

resource "aws_vpc" "this" {
  # 8 hosts are good enough for this example
  cidr_block = var.cidr_blocks.vpc

  tags = {
    Project     = "httpbin"
    Environment = "staging"
  }
}

resource "aws_subnet" "privates" {
  count                   = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.cidr_blocks[format("private_%s", count.index+1)]
  availability_zone       = format("%s-%s", var.aws_region, element(var.availability_zones, count.index))
  map_public_ip_on_launch = false

  tags = {
    Project     = "httpbin"
    Environment = "staging"
  }
}
