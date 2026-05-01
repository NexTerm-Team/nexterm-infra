resource "yandex_container_registry" "this" {
  name      = "${var.name_prefix}-cr"
  folder_id = var.folder_id
}

# Lifecycle policy: чистим старые образы, чтобы не платить за хранение.
# Сохраняем последние 10 тегов на репозиторий + всё за последние 30 дней.
resource "yandex_container_repository_lifecycle_policy" "cleanup" {
  for_each = toset(var.repository_names)

  name        = "cleanup-untagged"
  status      = "active"
  repository_id = yandex_container_repository.repos[each.key].id

  rule {
    description  = "Удаляем untagged образы старше 7 дней"
    expire_period = "168h"
    untagged     = true
  }

  rule {
    description    = "Оставляем последние 10 тегированных + всё за месяц"
    expire_period  = "720h"
    tag_regexp     = ".*"
    retained_top   = 10
  }
}

# Репозитории создаются явно — это удобно для назначения per-repo IAM-политик.
resource "yandex_container_repository" "repos" {
  for_each = toset(var.repository_names)
  name     = "${yandex_container_registry.this.id}/${each.key}"
}
