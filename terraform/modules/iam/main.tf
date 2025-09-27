# terraform/modules/iam/main.tf

# IAM User for developers (read-only access to EKS)
resource "aws_iam_user" "developer" {
  name = "${var.project_name}-developer-readonly"
  path = "/"

  tags = {
    Name        = "${var.project_name}-developer-readonly"
    Environment = var.environment
    Purpose     = "EKS read-only access for developers"
  }
}

# Access keys for the developer user
resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

# IAM Policy for EKS read-only access
resource "aws_iam_policy" "eks_readonly" {
  name        = "${var.project_name}-eks-readonly"
  description = "Read-only access to EKS cluster resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeUpdate",
          "eks:ListUpdates",
          "eks:DescribeFargateProfile",
          "eks:ListFargateProfiles",
          "eks:DescribeIdentityProviderConfig",
          "eks:ListIdentityProviderConfigs",
          "eks:DescribeAddon",
          "eks:ListAddons",
          "eks:ListTagsForResource"
        ]
        Resource = [
          var.cluster_arn,
          "${var.cluster_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:AccessKubernetesApi"
        ]
        Resource = var.cluster_arn
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-eks-readonly"
    Environment = var.environment
  }
}

# Attach the policy to the user
resource "aws_iam_user_policy_attachment" "developer_eks_readonly" {
  user       = aws_iam_user.developer.name
  policy_arn = aws_iam_policy.eks_readonly.arn
}

# Kubernetes RBAC - ClusterRole for read-only access
resource "kubernetes_cluster_role" "developer_readonly" {
  metadata {
    name = "${var.project_name}-developer-readonly"
  }

  rule {
    api_groups = [""]
    resources = [
      "pods",
      "pods/log",
      "services",
      "endpoints",
      "persistentvolumeclaims",
      "events",
      "configmaps",
      "secrets",
      "nodes",
      "namespaces"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "deployments",
      "replicasets",
      "statefulsets",
      "daemonsets"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources = [
      "ingresses"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources = [
      "jobs",
      "cronjobs"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources = [
      "pods",
      "nodes"
    ]
    verbs = ["get", "list"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources = [
      "horizontalpodautoscalers"
    ]
    verbs = ["get", "list", "watch"]
  }
}

# Kubernetes RBAC - ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "developer_readonly" {
  metadata {
    name = "${var.project_name}-developer-readonly"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.developer_readonly.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = aws_iam_user.developer.name
    api_group = "rbac.authorization.k8s.io"
  }
}

# AWS auth ConfigMap entry (adds the IAM user to the EKS cluster)
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      {
        userarn  = aws_iam_user.developer.arn
        username = aws_iam_user.developer.name
        groups   = ["system:authenticated"]
      }
    ])
  }

  force = true
}