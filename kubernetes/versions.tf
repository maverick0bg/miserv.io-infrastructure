locals {
  region        = "eu-west-1"
  name          = "miserv"
  cluster_name  = "miserv-io-eks-cluster"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0"
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

data "aws_eks_cluster" "default" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "default" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
  #   command     = "aws"
  # }
  token                  = data.aws_eks_cluster_auth.default.token
}

data "aws_availability_zones" "available" {}


resource "random_string" "suffix" {
  length  = 8
  special = false
}
