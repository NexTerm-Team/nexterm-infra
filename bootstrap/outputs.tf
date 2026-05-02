output "tf_service_account_id" {
  description = "ID service account для Terraform"
  value       = yandex_iam_service_account.tf.id
}

output "tf_service_account_name" {
  value = yandex_iam_service_account.tf.name
}

output "access_key" {
  description = "Static access key. Положить в env AWS_ACCESS_KEY_ID или ~/.aws/credentials."
  value       = yandex_iam_service_account_static_access_key.tf.access_key
  sensitive   = true
}

output "secret_key" {
  description = "Static secret key. Положить в env AWS_SECRET_ACCESS_KEY или ~/.aws/credentials."
  value       = yandex_iam_service_account_static_access_key.tf.secret_key
  sensitive   = true
}

output "state_bucket_name" {
  description = "Имя bucket для state. Вписать в backend.tf."
  value       = yandex_storage_bucket.tf_state.bucket
}

output "ydb_full_endpoint" {
  description = "Полный endpoint YDB. Используется в backend.tf как dynamodb endpoint."
  value       = yandex_ydb_database_serverless.tf_locks.document_api_endpoint
}

output "ydb_database_path" {
  description = "Document API path для YDB."
  value       = yandex_ydb_database_serverless.tf_locks.database_path
}

output "backend_config_hint" {
  description = "Готовый блок backend для копирования в основной Terraform."
  value       = <<-EOT
    # Скопируйте это в terraform/environments/prod/backend.tf:

    terraform {
      backend "s3" {
        endpoints = {
          s3       = "https://storage.yandexcloud.net"
          dynamodb = "${yandex_ydb_database_serverless.tf_locks.document_api_endpoint}"
        }
        bucket = "${yandex_storage_bucket.tf_state.bucket}"
        region = "ru-central1"
        key    = "prod/terraform.tfstate"

        dynamodb_table = "tf-locks"

        skip_region_validation      = true
        skip_credentials_validation = true
        skip_requesting_account_id  = true
        skip_s3_checksum            = true
        skip_metadata_api_check     = true

        # Аутентификация через env vars:
        #   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY (значения см. в outputs.access_key/secret_key)
      }
    }
  EOT
}
