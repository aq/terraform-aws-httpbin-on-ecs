provider "aws" {
  region = var.aws_region
}

# This is Paris region.
variable "aws_region" {
  default = "eu-west-3"
}

# To create a basic IP filtering to the entry points,
# fill in your IP through command line:
# terraform plan -var="operator-ip=184.168.131.241/32"
variable "operator-ip" {
  type = string
  # default = "0.0.0.0/0"
}

