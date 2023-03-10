locals {
  region       = "eu-west-1"
  name         = "miserv"
  vpc_cidr     = "10.0.0.0/16"
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)
  cluster_name = "miserv-io-eks-cluster"
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

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~>2.8.0"
    }
  }

  required_version = "~>1.3.6"
}

provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}


resource "random_string" "suffix" {
  length  = 8
  special = false
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
