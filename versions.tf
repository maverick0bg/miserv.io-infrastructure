locals {
  region        = "eu-west-1"
  instance_type = "t2.micro"
  name          = "miserv-db"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0"
    }
  }

  required_version = "1.3.6"
}

provider "aws" {
  region = local.region
}