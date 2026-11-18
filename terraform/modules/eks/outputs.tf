output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_security_group_id" {
  description = "SG del cluster EKS, aplicado a los ENIs de los nodos gestionados"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}
