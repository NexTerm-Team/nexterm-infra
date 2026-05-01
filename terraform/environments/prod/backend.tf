# Remote backend в YC Object Storage + YDB-locks.
#
# ВНИМАНИЕ: bucket и YDB endpoint создаются bootstrap'ом (см. ../../../bootstrap/).
# После первого `terraform apply` в bootstrap скопируйте значения из его outputs
# в этот файл (placeholder'ы ниже отмечены TODO).
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
      # TODO: подставить из bootstrap output `ydb_full_endpoint`
      dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/<CLOUD_ID>/<YDB_NODE_ID>"
    }

    bucket = "nexterm-tf-state"
    region = "ru-central1"
    key    = "prod/terraform.tfstate"

    dynamodb_table = "tf-locks"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
  }
}
