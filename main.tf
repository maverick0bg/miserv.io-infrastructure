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
    aws-ebs-csi-driver = {
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

  manage_aws_auth_configmap = true
  aws_auth_roles = [

    {
      "groups" : ["system:masters"],
      "rolearn" : aws_iam_role.github_oidc_auth_role.arn
      "username" : "GitHubActions"
    },
    {
      "groups" : ["system:masters"],
      "rolearn" : aws_iam_role.amazon_role.arn
      "username" : "maverick.bg"
    }
  ]
}

#resource "aws_eks_addon" "addons" {
#  for_each          = { for addon in var.additional_addons : addon.name => addon }
#  cluster_name      = module.eks.cluster_name
#  addon_name        = each.value.name
#  addon_version     = each.value.version
#  resolve_conflicts = "OVERWRITE"
#}

resource "kubernetes_annotations" "role_annotanion" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name = "ebs-csi-controller-sa"
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::527321763428:role/ebs_csi_driver_role"
  }

  force = true
  depends_on = [
    module.eks,
  ]
}

module "miserv_io_namespace" {
  source = "git::https://github.com/gruntwork-io/terraform-kubernetes-namespace.git//modules/namespace?ref=v0.1.0"
  name   = "miserv-io"
}

module "tobs_namespace" {
  source = "git::https://github.com/gruntwork-io/terraform-kubernetes-namespace.git//modules/namespace?ref=v0.1.0"
  name   = "tobs"
}
