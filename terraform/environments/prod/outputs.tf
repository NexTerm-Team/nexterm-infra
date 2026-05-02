output "k8s_cluster_id" {
  value = module.k8s.cluster_id
}

output "k8s_external_endpoint" {
  description = "Public endpoint k8s API. Для kubeconfig: yc managed-kubernetes cluster get-credentials"
  value       = module.k8s.external_v4_endpoint
}

output "k8s_get_credentials_cmd" {
  description = "Команда для получения kubeconfig"
  value       = "yc managed-kubernetes cluster get-credentials ${module.k8s.cluster_name} --external --force"
}

output "container_registry_url" {
  description = "URL для docker push (cr.yandex/<id>)"
  value       = module.container_registry.registry_url
}

output "container_registry_id" {
  value = module.container_registry.registry_id
}

output "dns_name_servers" {
  description = "NS-серверы YC. Пропишите их в RU-Center для делегирования зоны nexterm.ru."
  value       = module.dns.name_servers
}

output "wif_federation_id" {
  description = "OIDC federation ID. В GitHub Actions передаётся как параметр в yc-action."
  value       = module.wif.federation_id
}

output "wif_ci_service_accounts" {
  description = "Service account ID для каждого CI-репо. Используется при ручном debug; в самих workflow обмениваем через federated_credential_id."
  value       = module.wif.ci_service_accounts
}

output "wif_federated_credentials" {
  description = "Federated credential ID на репо. Это значение идёт в GitHub Secret YC_FEDERATED_CREDENTIAL_ID — параметр для yc-actions/yc-iam-token-fed-credential."
  value       = module.wif.federated_credentials
}
