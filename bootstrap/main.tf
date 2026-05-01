# ============================================================================
# Service account для Terraform
# ============================================================================
resource "yandex_iam_service_account" "tf" {
  name        = var.tf_sa_name
  description = "Terraform admin для управления ресурсами nexterm"
  folder_id   = var.folder_id
}

# Роль admin на folder — Terraform может всё внутри этого folder.
# Шире, чем editor (включает управление IAM-привязками внутри folder).
resource "yandex_resourcemanager_folder_iam_member" "tf_admin" {
  folder_id = var.folder_id
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.tf.id}"
}

# Дополнительная роль на cloud-уровне нужна, если SA должен видеть
# ресурсы вне своего folder (например, billing-account для проверок).
# Для начала — только folder-scope.

# ============================================================================
# Static access key для S3-API (Object Storage backend Terraform)
# ============================================================================
resource "yandex_iam_service_account_static_access_key" "tf" {
  service_account_id = yandex_iam_service_account.tf.id
  description        = "S3-доступ для Terraform backend"
}

# ============================================================================
# Object Storage bucket для state
# ============================================================================
resource "yandex_storage_bucket" "tf_state" {
  bucket    = var.state_bucket_name
  folder_id = var.folder_id

  # Используем static keys SA для управления bucket'ом.
  access_key = yandex_iam_service_account_static_access_key.tf.access_key
  secret_key = yandex_iam_service_account_static_access_key.tf.secret_key

  # Versioning ОБЯЗАТЕЛЬНО для state — позволяет откатиться при corrupted state.
  versioning {
    enabled = true
  }

  # Шифрование at-rest через managed key YC.
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Lifecycle: храним noncurrent versions 90 дней, потом чистим.
  lifecycle_rule {
    id      = "expire-old-versions"
    enabled = true
    noncurrent_version_expiration {
      days = 90
    }
  }

  # Закрываем публичный доступ на всякий случай.
  anonymous_access_flags {
    read = false
    list = false
  }
}

# ============================================================================
# YDB Serverless для Terraform state-locks
# ============================================================================
resource "yandex_ydb_database_serverless" "tf_locks" {
  name        = var.ydb_database_name
  folder_id   = var.folder_id
  description = "Блокировки Terraform state. Используется как DynamoDB-совместимое API."

  # Serverless — pay per use, дешёво для редких операций блокировок.
  # Автоматический deletion protection.
  deletion_protection = true
}
