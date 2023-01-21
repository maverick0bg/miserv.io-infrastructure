module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.5.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.24"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "fg-${local.name}"
      selectors = [
        {
          namespace = "miserv-io"
        }
      ]
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    
    {
      "groups" : ["system:masters"],
      "rolearn" : aws_iam_role.github_oidc_auth_role.arn
      "username" : "GitHubActions"
    },
    {
      "groups" : ["system:masters"],
      "rolearn" : aws_iam_role.amazon-role.arn
      "username" : "maverick.bg"
    }
  ]
}

