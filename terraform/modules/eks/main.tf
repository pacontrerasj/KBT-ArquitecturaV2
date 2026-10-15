# --- CONFIGURACIÓN PRO ---
# resource "aws_kms_key" "eks" {
#   description             = "EKS Secret Encryption Key"
#   deletion_window_in_days = 7
# }
# -------------------------

resource "aws_eks_cluster" "main" {
  # checkov:skip=CKV_AWS_38: Endpoint público necesario para CI/CD
  # checkov:skip=CKV_AWS_39: Endpoint público necesario para CI/CD
  name     = "freshbox-eks"
  role_arn = aws_iam_role.eks_cluster.arn

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

variable "subnet_ids" { type = list(string) }

resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "eks.amazonaws.com" } }]
  })
}
