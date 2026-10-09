output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = var.region
}

output "karpenter_queue_name" {
  value = module.karpenter.queue_name
}

output "karpenter_node_role_name" {
  value = module.karpenter.node_iam_role_name
}
