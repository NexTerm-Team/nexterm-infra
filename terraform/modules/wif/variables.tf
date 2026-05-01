variable "folder_id" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "github_owner" {
  description = "Owner GitHub-репо (org или user). Например 'abukatov' или 'NexTerm-Team'"
  type        = string
}

variable "container_registry_id" {
  type = string
}

variable "repos" {
  description = "Map имён компонентов на репо и разрешённую ref для деплоя"
  type = map(object({
    repo        = string # name of the GitHub repo (without owner)
    allowed_ref = string # branch имя, обычно 'main'
  }))
}
