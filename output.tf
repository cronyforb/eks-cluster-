output "cluster_name" {
  value = aws_eks_cluster.louis.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.louis.endpoint
}

output "cluster_status" {
  value = aws_eks_cluster.louis.status
}

output "node_group_status" {
  value = aws_eks_node_group.workers.status
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region us-east-1 --name louis"
}
