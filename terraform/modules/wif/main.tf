# ============================================================================
# Workload Identity Federation для GitHub Actions
#
# Идея: GitHub Actions при выполнении workflow получает OIDC-токен
# от https://token.actions.githubusercontent.com. Этот токен можно обменять
# на короткоживущий IAM-токен YC через WIF, без хранения JSON-ключей в репо.
#
# В YC это сделано через:
#   - workload_identity.federation — описывает trust к OIDC-провайдеру (GitHub)
#   - service_account_iam_binding — привязка к конкретному SA
#   - условия subject (sub claim) — ограничивают какие именно workflow'ы
#     могут аутентифицироваться (по репо, по ветке)
# ============================================================================

# OIDC-федерация на уровне cloud (одна на всё облако, переиспользуется).
resource "yandex_iam_workload_identity_oidc_federation" "github" {
  name        = "github-actions"
  folder_id   = var.folder_id
  description = "Federation для GitHub Actions OIDC"

  audiences = ["https://github.com/${var.github_owner}"]
  issuer    = "https://token.actions.githubusercontent.com"

  # Public JWKS GitHub OIDC.
  jwks_url = "https://token.actions.githubusercontent.com/.well-known/jwks"
}

# По одному SA на каждый компонент-репо. Узкие права.
resource "yandex_iam_service_account" "ci" {
  for_each = var.repos

  name        = "${var.name_prefix}-ci-${each.key}"
  description = "CI service account для репо ${each.value.repo}"
  folder_id   = var.folder_id
}

# Привязка federation → SA: какой subject (sub в OIDC-токене) может
# аутентифицироваться как этот SA.
# subject формата: repo:OWNER/REPO:ref:refs/heads/main
resource "yandex_iam_workload_identity_federated_credential" "ci" {
  for_each = var.repos

  service_account_id = yandex_iam_service_account.ci[each.key].id
  federation_id      = yandex_iam_workload_identity_oidc_federation.github.id
  external_subject_id = "repo:${var.github_owner}/${each.value.repo}:ref:refs/heads/${each.value.allowed_ref}"
}

# Push образов в свой репозиторий Container Registry.
resource "yandex_container_registry_iam_binding" "ci_push" {
  for_each = var.repos

  registry_id = var.container_registry_id
  role        = "container-registry.images.pusher"
  members     = ["serviceAccount:${yandex_iam_service_account.ci[each.key].id}"]
}

# Право управлять deployments в namespace компонента (через k8s ServiceAccount-token,
# выданный самому SA на уровне folder, плюс RBAC внутри кластера —
# RBAC делается отдельно в k8s-манифестах).
resource "yandex_resourcemanager_folder_iam_member" "ci_k8s_viewer" {
  for_each = var.repos

  folder_id = var.folder_id
  role      = "k8s.cluster-api.cluster-admin"
  member    = "serviceAccount:${yandex_iam_service_account.ci[each.key].id}"
}
