variable "folder_id" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "repository_names" {
  description = "Список репозиториев в registry (без префикса registry-id)"
  type        = list(string)
  default     = ["web", "api"]
}
