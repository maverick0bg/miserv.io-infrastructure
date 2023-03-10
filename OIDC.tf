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

resource "aws_iam_role" "amazon_role" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
					"eks.amazonaws.com",
					"ec2.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
				],
        "AWS": "arn:aws:iam::527321763428:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon_role_amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.amazon_role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "amazon_role_amazon_eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.amazon_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_role_amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.amazon_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_role_amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.amazon_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_role_amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.amazon_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_role_amazon_eks_fargate_pod_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.amazon_role.name
}

resource "aws_iam_role" "ebs_csi_driver_role" {
  name               = "ebs_csi_driver_role"
  assume_role_policy = <<POLICY1
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::527321763428:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/B3C42311D68E21B4984D55F33F8800E6"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringLike": {
            "oidc.eks.eu-west-1.amazonaws.com/id/*:aud": "sts.amazonaws.com",
            "oidc.eks.eu-west-1.amazonaws.com/id/*:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  }
  POLICY1
}

resource "aws_iam_role_policy_attachment" "atachment_amazon_eks_ebs_csi_driver_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role.name
}
