# --- CONFIGURACIÓN PRO ---
# resource "aws_kms_key" "eks" {
#   description             = "EKS Secret Encryption Key"
#   deletion_window_in_days = 7
# }
# -------------------------

data "aws_iam_role" "lab" {
  name = "LabRole"
}

resource "aws_eks_cluster" "main" {
  # checkov:skip=CKV_AWS_38: Endpoint público necesario para CI/CD
  # checkov:skip=CKV_AWS_39: Endpoint público necesario para CI/CD
  # checkov:skip=CKV_AWS_58: KMS no disponible en AWS Academy Learner Lab
  name     = "freshbox-eks"
  role_arn = data.aws_iam_role.lab.arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # --- CONFIGURACIÓN PRO: Descomentar en entorno con permisos KMS ---
  # encryption_config {
  #   provider {
  #     key_arn = aws_kms_key.eks.arn
  #   }
  #   resources = ["secrets"]
  # }
  # -----------------------------------------------------------------

  vpc_config {
    subnet_ids = var.subnet_ids
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "freshbox-nodes"
  node_role_arn   = data.aws_iam_role.lab.arn
  subnet_ids      = var.subnet_ids

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  tags = { Name = "freshbox-nodes" }
}

variable "subnet_ids" { type = list(string) }
