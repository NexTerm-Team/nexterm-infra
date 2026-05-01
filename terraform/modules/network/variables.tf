variable "folder_id" {
  type = string
}

variable "name_prefix" {
  description = "Префикс имён ресурсов, например 'nexterm-prod'"
  type        = string
}

variable "zones" {
  description = "Список зон, в которых заводим subnet'ы (заранее, под HA на будущее)"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
}

variable "subnet_cidrs" {
  description = "CIDR'ы subnet'ов по зонам"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.10.10.0/24"
    "ru-central1-b" = "10.10.20.0/24"
    "ru-central1-d" = "10.10.30.0/24"
  }
}
