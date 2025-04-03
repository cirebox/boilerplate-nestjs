/**
 * Módulo de Kubernetes (EKS) para AWS
 * 
 * Este módulo cria um cluster EKS otimizado para controle de custos
 * com node groups e políticas de auto scaling.
 */

locals {
  cluster_name                  = "${var.project_name}-${var.environment}-eks"
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler"
}

# Obter informações da VPC
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Role IAM para o cluster EKS
resource "aws_iam_role" "eks_cluster" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

# Anexar políticas necessárias à role do cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# Role IAM para os nós do EKS
resource "aws_iam_role" "eks_nodes" {
  name = "${local.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

# Anexar políticas necessárias à role dos nós
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Grupo de segurança para o cluster EKS
resource "aws_security_group" "eks_cluster" {
  name        = "${local.cluster_name}-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-sg"
  })
}

# Regra de entrada para permitir comunicação entre nós e o plano de controle
resource "aws_security_group_rule" "eks_cluster_ingress" {
  description       = "Allow communication between nodes and control plane"
  security_group_id = aws_security_group.eks_cluster.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
}

# Cluster EKS
resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id]
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.environment != "prod" # Somente ambientes não produtivos têm acesso público
  }

  # Otimização para economia de custos: desativar logs de cluster em dev
  enabled_cluster_log_types = var.environment == "prod" ? ["api", "audit", "authenticator", "controllerManager", "scheduler"] : []

  # Garantir que as IAM roles sejam criadas antes do cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]

  # Proteção contra destruição acidental do cluster - usando valor fixo em vez de expressão condicional
  lifecycle {
    prevent_destroy = false # Alterado de var.environment == "prod" ? true : false para um valor fixo
    # Nota: Para ambiente de produção, recomenda-se alterar para true manualmente ou usar módulos separados
  }

  tags = var.tags
}

# Grupo de nós EKS - Primário (otimizado para custos)
resource "aws_eks_node_group" "primary" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.cluster_name}-primary"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.subnet_ids

  # Configuração de instâncias
  ami_type       = "AL2_x86_64" # Amazon Linux 2 para melhor compatibilidade
  instance_types = var.node_instance_types
  capacity_type  = var.environment == "prod" ? "ON_DEMAND" : "SPOT" # Usar spot instances em dev/staging para economia
  disk_size      = 20

  # Configuração de auto scaling
  scaling_config {
    desired_size = var.desired_nodes
    min_size     = var.min_nodes
    max_size     = var.max_nodes
  }

  # Otimização para ciclo de vida dos nós: estratégia de atualização gradual
  update_config {
    max_unavailable = 1
  }

  # Garantir que o cluster esteja pronto antes de criar os nós
  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  # Ignorar mudanças de escala feitas externamente
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = var.tags
}

# IAM Policy para o Cluster Autoscaler
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.cluster_name}-cluster-autoscaler"
  description = "Policy para permitir o funcionamento do Cluster Autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })

  tags = var.tags
}

# IAM Role para o Cluster Autoscaler (IRSA - IAM Roles for Service Accounts)
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${local.cluster_name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_eks_cluster.main.identity[0].oidc[0].issuer
        }
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

# Métricas CloudWatch para monitoramento de custos do EKS
resource "aws_cloudwatch_metric_alarm" "node_cpu_utilization" {
  count               = var.environment == "prod" ? 1 : 0
  alarm_name          = "${local.cluster_name}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU utilization is too high on EKS nodes, consider scaling"

  # Usando dimensões corretas para monitorar o EKS
  dimensions = {
    AutoScalingGroupName = "${local.cluster_name}-primary-*"
  }

  alarm_actions = []
  tags          = var.tags
}

# Data source para obter a região atual
data "aws_region" "current" {}