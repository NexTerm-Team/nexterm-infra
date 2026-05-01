variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID, в котором живут все ресурсы nexterm"
  type        = string
}

variable "zone" {
  description = "Зона по умолчанию для региональных ресурсов"
  type        = string
  default     = "ru-central1-a"
}

variable "tf_sa_name" {
  description = "Имя service account для Terraform"
  type        = string
  default     = "nexterm-tf"
}

variable "state_bucket_name" {
  description = "Имя Object Storage bucket для Terraform state. Должно быть глобально уникальным."
  type        = string
  default     = "nexterm-tf-state"
}

variable "ydb_database_name" {
  description = "Имя Serverless YDB-базы для блокировок Terraform"
  type        = string
  default     = "nexterm-tf-locks"
}
