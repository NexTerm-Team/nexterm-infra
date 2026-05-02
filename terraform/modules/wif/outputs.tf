output "federation_id" {
  description = "ID OIDC-federation. Используется в GitHub Actions yc-cli для exchange токена."
  value       = yandex_iam_workload_identity_oidc_federation.github.id
}

output "ci_service_accounts" {
  description = "Map repo → service_account_id. Положить в GitHub Secrets как YC_SA_ID_<REPO>."
  value       = { for k, sa in yandex_iam_service_account.ci : k => sa.id }
}

output "federated_credentials" {
  description = "Map repo → federated_credential_id. Это значение идёт в GitHub Secret YC_FEDERATED_CREDENTIAL_ID — параметр для yc-actions/yc-iam-token-fed-credential."
  value       = { for k, fc in yandex_iam_workload_identity_federated_credential.ci : k => fc.id }
}
