# ==============================================================================
# 1. IAM Role para o Control Plane do Cluster EKS (Opção B — Conta Pessoal)
# ==============================================================================
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.project_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = {
    Name = "${var.project_name}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# ==============================================================================
# 2. IAM Role para os Worker Nodes (Managed Node Group)
# ==============================================================================
data "aws_iam_policy_document" "eks_nodes_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_nodes" {
  name               = "${var.project_name}-eks-nodegroup-role"
  assume_role_policy = data.aws_iam_policy_document.eks_nodes_assume_role.json

  tags = {
    Name = "${var.project_name}-eks-nodegroup-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# ==============================================================================
# 3. IRSA (IAM Roles for Service Accounts) — evaluation-service (SQS Producer)
# ==============================================================================
data "aws_iam_policy_document" "evaluation_irsa_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:togglemaster-evaluation:evaluation-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "evaluation_irsa" {
  name               = "${var.project_name}-evaluation-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.evaluation_irsa_assume.json

  tags = {
    Name    = "${var.project_name}-evaluation-irsa-role"
    Service = "evaluation-service"
  }
}

resource "aws_iam_role_policy" "evaluation_sqs_policy" {
  name = "${var.project_name}-evaluation-sqs-policy"
  role = aws_iam_role.evaluation_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

# ==============================================================================
# 4. IRSA — analytics-service (SQS Consumer + DynamoDB Writer/Reader)
# ==============================================================================
data "aws_iam_policy_document" "analytics_irsa_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:togglemaster-analytics:analytics-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "analytics_irsa" {
  name               = "${var.project_name}-analytics-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.analytics_irsa_assume.json

  tags = {
    Name    = "${var.project_name}-analytics-irsa-role"
    Service = "analytics-service"
  }
}

resource "aws_iam_role_policy" "analytics_sqs_dynamodb_policy" {
  name = "${var.project_name}-analytics-sqs-dynamodb-policy"
  role = aws_iam_role.analytics_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:DescribeTable"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# ==============================================================================
# 5. IRSA — KEDA Operator (Monitoramento de Profundidade da Fila SQS)
# ==============================================================================
data "aws_iam_policy_document" "keda_irsa_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:keda:keda-operator"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "keda_irsa" {
  name               = "${var.project_name}-keda-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.keda_irsa_assume.json

  tags = {
    Name    = "${var.project_name}-keda-irsa-role"
    Service = "keda-operator"
  }
}

resource "aws_iam_role_policy" "keda_sqs_policy" {
  name = "${var.project_name}-keda-sqs-policy"
  role = aws_iam_role.keda_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}
