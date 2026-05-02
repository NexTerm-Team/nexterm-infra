# Remote backend в YC Object Storage + YDB-locks.
# Bucket и YDB endpoint созданы bootstrap'ом (см. ../../../bootstrap/).
#
# Для аутентификации:
#   export AWS_ACCESS_KEY_ID="<bootstrap output: access_key>"
#   export AWS_SECRET_ACCESS_KEY="<bootstrap output: secret_key>"
#   export YC_TOKEN="$(yc iam create-token)"
#
terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket = "nexterm-tf-state"
    region = "ru-central1"
    key    = "prod/terraform.tfstate"

    # S3-native блокировки (через дополнительный *.tflock-файл в bucket).
    # Заменяет deprecated dynamodb_table — не требует YDB.
    use_lockfile = true

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
  }
}
