output "registry_id" {
  value = yandex_container_registry.this.id
}

output "registry_name" {
  value = yandex_container_registry.this.name
}

output "registry_url" {
  description = "URL для docker push: cr.yandex/<id>/<repo>:<tag>"
  value       = "cr.yandex/${yandex_container_registry.this.id}"
}

output "repository_ids" {
  value = { for k, r in yandex_container_repository.repos : k => r.id }
}
