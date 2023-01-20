resource "aws_eks_cluster" "eks" {

  name    = local.cluster_name
  role_arn = aws_iam_role.amazon-role.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }
  depends_on = [
    aws_iam_role_policy_attachment.amazon-role-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.amazon-role-AmazonEKSVPCResourceController,
  ]
}


# Creates a kubernetes cluster role with necessary access to deploy
resource "kubernetes_cluster_role" "github_oidc_cluster_role" {
  metadata {
    name = "github-oidc-cluster-role"

  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
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
        "groups": ["system:bootstrappers", "system:nodes"],
        "rolearn": aws_iam_role.amazon-role.workers.arn
        "username": "system:node:{{EC2PrivateDNSName}}"
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

