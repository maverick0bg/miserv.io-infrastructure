# this idea comes from https://blog.devops.dev/deploy-to-amazon-eks-using-github-actions-packages-easy-way-out-70b153f04e38
# Configure AWS Credentials Action requests token with audience sts.amazonaws.com. aud field of the token
# Thumbprint is the signature for CA's certificate. More info @ https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
# Url is url of the id token provider. iss field of the token
resource "aws_iam_openid_connect_provider" "github" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  url             = "https://token.actions.githubusercontent.com"
}

# The values field under condition is used to allow access for workflow triggered from specific repo and environment or branch or tag or "pull_request"
# For more info @ https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
data "aws_iam_policy_document" "github_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.github.url, "https://", "")}:sub"
      values   = ["repo:maverick0bg/miserv.io*"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }
  }
}

# Create a role policy that would allow fetching cluster info. 
# This would help us avoid storing cluster's kube config in GitHub Action's secrets
resource "aws_iam_role_policy" "github_oidc_eks_policy" {
  name = "github-oidc-eks-policy"
  role = aws_iam_role.github_oidc_auth_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : "eks:DescribeCluster",
        "Resource" : "arn:aws:eks:*:*:cluster/*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "eks:ListClusters",
        "Resource" : "*"
      }
    ]
  })
}

# Creating a role. It will used as value to role_to_assume for Configure AWS Crendentials action.
resource "aws_iam_role" "github_oidc_auth_role" {
  assume_role_policy = data.aws_iam_policy_document.github_assume_role_policy.json
  name               = "github-oidc-auth-role"
}

resource "aws_iam_role" "amazon-role" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon-role-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.amazon-role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "amazon-role-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.amazon-role.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.amazon-role.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.amazon-role.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.amazon-role.name
}