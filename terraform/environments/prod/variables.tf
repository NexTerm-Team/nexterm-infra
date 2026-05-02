variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "default_zone" {
  type    = string
  default = "ru-central1-a"
}

variable "name_prefix" {
  type    = string
  default = "nexterm-prod"
}

variable "domain" {
  description = "Корневой домен приложения"
  type        = string
  default     = "nexterm.ru"
}

variable "github_owner" {
  description = "Владелец GitHub-репо (для WIF subject)"
  type        = string
  default     = "abukatov"
}

# Репо, для которых заводим CI-SA + WIF-федерацию.
# При появлении новых компонентов — дополнять.
variable "ci_repos" {
  type = map(object({
    repo        = string
    allowed_ref = string
  }))
  default = {
    web = {
      repo        = "nexterm-web"
      allowed_ref = "main"
    }
    # api = { repo = "nexterm-api", allowed_ref = "main" }
  }
}
