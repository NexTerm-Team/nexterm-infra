# Bootstrap — chicken-and-egg для основного Terraform

Этот мини-Terraform создаёт ресурсы, которые нужны самому **основному** Terraform для работы:

1. **Service account `nexterm-tf`** с ролью `admin` на folder.
2. **Static access key** для этого SA (нужен для S3-совместимого Object Storage).
3. **Object Storage bucket `nexterm-tf-state`** с включённым versioning.
4. **YDB Serverless** + table `tf-locks` для блокировок Terraform state.

State самого bootstrap'а — **локальный** (`terraform.tfstate` в этой папке). Он коммитится в репо в зашифрованном виде через `git-crypt`/`sops` или хранится только локально (см. `.gitignore`). После начального apply этот код почти никогда не трогается.

## Когда использовать

- Один раз при создании окружения с нуля.
- При полной переустановке state-инфраструктуры (редко).

## Применение

```bash
# 1. Установить yc CLI и залогиниться (через OAuth)
yc init

# 2. Получить OAuth-токен и положить в env
export YC_TOKEN=$(yc iam create-token)

# 3. Применить Terraform
cd bootstrap/
cp terraform.tfvars.example terraform.tfvars
# отредактировать terraform.tfvars если нужно
terraform init
terraform plan
terraform apply
```

После применения terraform выведет:
- `access_key` / `secret_key` — занести в `~/.aws/credentials` или экспортировать в env (см. ниже).
- `bucket_name`, `ydb_endpoint`, `ydb_path` — нужно вписать в `terraform/environments/prod/backend.tf`.

## Доступ к state из основного Terraform

```bash
export AWS_ACCESS_KEY_ID="<access_key из output bootstrap'а>"
export AWS_SECRET_ACCESS_KEY="<secret_key из output bootstrap'а>"
```

Или в `~/.aws/credentials`:

```ini
[nexterm]
aws_access_key_id = ...
aws_secret_access_key = ...
```

И в основном Terraform: `AWS_PROFILE=nexterm terraform init`.

## Безопасность

- **Не коммить `terraform.tfvars`** — там OAuth-токен/идентификаторы.
- **Не коммить static access keys в plain text** — в outputs Terraform они помечены `sensitive`, но выводятся в локальный `terraform.tfstate`. Этот state сам по себе — секрет.
- Долгосрочное решение — переехать на YC Lockbox для хранения `access_key`/`secret_key` и External Secrets Operator в кластере. Пока — локальный state в этой папке + `.gitignore`.
