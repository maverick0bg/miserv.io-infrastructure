module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.5.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.24"

  vpc_id                         = module.vpc-eks.vpc_id
  subnet_ids                     = module.vpc-eks.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  # create_aws_auth_configmap = true
  # manage_aws_auth_configmap = true
  # aws_auth_roles = [
  #   {
  #     userarn  = "arn:aws:iam::527321763428:user/gh-actions"
  #     username = "gh-actions"
  #     groups   = ["system:authenticated", "system:bootstrappers", "system:nodes", "eks-console-dashboard-full-access-group"]
  #   },
  # ]

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}


# Creates a kubernetes cluster role with necessary access to deploy
resource "kubernetes_cluster_role" "github_oidc_cluster_role" {
  metadata {
    name = "github-oidc-cluster-role"

  }

  rule {
    api_groups = ["*"]
    resources  = ["deployments", "pods", "services"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

# Creates a cluster role binding between the above kubernetes cluster role and the user
resource "kubernetes_cluster_role_binding" "github_oidc_cluster_role_binding" {
  metadata {
    name = "github-oidc-cluster-role-binding"
  }

  subject {
    kind      = "User"
    name      = "github-oidc-auth-user"
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.github_oidc_cluster_role.metadata[0].name
  }
}

resource "kubernetes_config_map" "aws-auth" {
  data = {
    "mapRoles" = yamlencode([
      {
        "groups" : ["system:bootstrappers", "system:nodes"],
        "rolearn" : aws_iam_role.github_oidc_auth_role.arn
        "username" : "system:admin"
      },
      {
        "rolearn" : aws_iam_role.github_oidc_auth_role.arn
        "username" : "github-oidc-auth-user"

      }
    ])

    "mapAccounts" = yamlencode([])
    "mapUsers"    = yamlencode([])
  }

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
      "terraform.io/module"          = "terraform-aws-modules.eks.aws"
    }
  }
}

resource "kubernetes_namespace" "example" {
  metadata {
    name = "miserv-io"
  }
}

