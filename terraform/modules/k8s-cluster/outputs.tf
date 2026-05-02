output "cluster_id" {
  value = yandex_kubernetes_cluster.this.id
}

output "cluster_name" {
  value = yandex_kubernetes_cluster.this.name
}

output "external_v4_endpoint" {
  description = "Public endpoint k8s API. Используется в kubeconfig."
  value       = yandex_kubernetes_cluster.this.master[0].external_v4_endpoint
}

output "ca_certificate" {
  description = "CA cert k8s API"
  value       = yandex_kubernetes_cluster.this.master[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_sa_id" {
  value = yandex_iam_service_account.cluster.id
}

output "nodes_sa_id" {
  value = yandex_iam_service_account.nodes.id
}

output "kms_key_id" {
  value = yandex_kms_symmetric_key.k8s.id
}

output "node_group_id" {
  value = yandex_kubernetes_node_group.this.id
}
