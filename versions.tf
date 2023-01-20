locals {
  region        = "eu-west-1"
  instance_type = "t2.micro"
  name          = "miserv"
  vpc_cidr      = "10.0.0.0/16"
  azs           = slice(data.aws_availability_zones.available.names, 0, 3)
  cluster_name  = "miserv-io-eks-cluster"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16.1"
    }
  }

  required_version = "~>1.3.6"
}

provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    command     = "aws"
  }

}

data "aws_availability_zones" "available" {}


resource "random_string" "suffix" {
  length  = 8
  special = false
}
