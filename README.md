# nexterm-infra

Инфраструктура и CI/CD для всей экосистемы [nexterm](https://github.com/abukatov/nexterm-web): Terraform для Yandex Cloud, Helm-чарты для k8s, переиспользуемые GitHub Actions workflow'ы.

## Что внутри

```
.
├── bootstrap/               # Мини-Terraform для chicken-and-egg
│                            # state-инфраструктуры (SA, bucket, YDB-locks).
│                            # Запускается один раз вручную.
│
├── terraform/
│   ├── environments/prod/   # Composition модулей для prod-окружения.
│   └── modules/
│       ├── network/         # VPC, subnets, security groups
│       ├── k8s-cluster/     # Managed Kubernetes (zonal master + nodegroup)
│       ├── container-registry/
│       ├── dns/             # Публичная DNS-зона nexterm.ru
│       └── wif/             # Workload Identity Federation для GitHub Actions
│
├── k8s/
│   ├── bootstrap/           # Helm-values для ingress-nginx, cert-manager
│   │                        # + ClusterIssuer'ы для Let's Encrypt
│   └── apps/
│       └── web/             # Helm-чарт для nexterm-web (лендинг)
│
├── compose/
│   └── dev/                 # docker-compose для локальной разработки
│
└── .github/workflows/
    ├── terraform.yml                # plan/apply Terraform
    └── reusable-k8s-deploy.yml      # вызывается из компонентных репо
```

## Архитектурные решения

- ADR 001 — Yandex Cloud + Managed k8s (в vault: `Projects/nexterm/decisions/001-yandex-cloud-managed-k8s.md`)
- ADR infra/001 — NGINX Ingress + cert-manager
- ADR infra/002 — Terraform state в YC Object Storage

## Полный bootstrap с нуля

> Это сценарий первичной установки. После него инфраструктура поддерживается через PR в этот репо + GitHub Actions.

### 0. Предусловия

- Активный аккаунт Yandex Cloud с биллингом
- `cloud_id`, `folder_id`, `domain` (`nexterm.ru` куплен у RU-Center)
- Установлены: `yc` CLI, `terraform >= 1.6`, `kubectl`, `helm`, `docker`
- Авторизация: `yc init`

### 1. Bootstrap state-инфраструктуры

```bash
cd bootstrap/
cp terraform.tfvars.example terraform.tfvars
# отредактировать terraform.tfvars (id'ы уже подставлены)

export YC_TOKEN=$(yc iam create-token)

terraform init
terraform plan
terraform apply
```

Output даст:
- `access_key` / `secret_key` — занесите в `~/.aws/credentials` или env
- `state_bucket_name`, `ydb_full_endpoint` — впишите в `terraform/environments/prod/backend.tf`

### 2. Основной Terraform — apply

```bash
cd ../terraform/environments/prod/
cp terraform.tfvars.example terraform.tfvars

# backend.tf уже почти готов, осталось вписать ydb endpoint из bootstrap output

export AWS_ACCESS_KEY_ID="<bootstrap output: access_key>"
export AWS_SECRET_ACCESS_KEY="<bootstrap output: secret_key>"
export YC_TOKEN=$(yc iam create-token)

terraform init
terraform plan
terraform apply
```

Output даст:
- `k8s_get_credentials_cmd` — команда для kubeconfig
- `dns_name_servers` — пропишите в RU-Center как NS для `nexterm.ru`
- `wif_federation_id`, `wif_ci_service_accounts` — положите в GitHub Secrets каждого репо

### 3. Получить kubeconfig

```bash
yc managed-kubernetes cluster get-credentials nexterm-prod-k8s --external --force
kubectl get nodes
```

### 4. k8s bootstrap

См. `k8s/bootstrap/README.md`. Кратко:

```bash
# ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  -f k8s/bootstrap/ingress-nginx/values.yaml

# Узнать публичный IP LB:
kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# → обновить terraform/environments/prod/main.tf: module.dns.apex_a_record = "<IP>"
# → terraform apply (создаст A-запись nexterm.ru → IP)

# cert-manager
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set installCRDs=true \
  -f k8s/bootstrap/cert-manager/values.yaml

# ClusterIssuer'ы (только после делегирования NS):
kubectl apply -f k8s/bootstrap/cert-manager/cluster-issuer.yaml
```

### 5. GitHub Secrets / Variables в репо компонентов

**Secrets** (Settings → Secrets and variables → Actions):
- `YC_FEDERATED_CREDENTIAL_ID` — из `wif_ci_service_accounts.<component>` Terraform output
- `YC_CLUSTER_ID` — из `k8s_cluster_id`

**Variables**:
- `YC_CONTAINER_REGISTRY_ID` — из `container_registry_id`

### 6. Первый деплой nexterm-web

`git push origin main` в `nexterm-web` → GitHub Actions:
1. Сборка Docker-образа.
2. Push в `cr.yandex/<id>/web:<sha>` (auth через WIF).
3. Reusable workflow из этого репо: `helm upgrade k8s/apps/web/`.
4. cert-manager выпускает TLS Let's Encrypt.
5. `https://nexterm.ru` живой.

## Локальная разработка

`compose/dev/docker-compose.yml` — пока только web.

## Безопасность

- `terraform.tfvars` — в `.gitignore`, не коммитим.
- Static access keys (от bootstrap) — в `~/.aws/credentials` или env, не в git.
- Сертификаты Let's Encrypt — managed cert-manager'ом, в k8s Secrets (encrypted at rest через KMS).
- TODO для production-ready: External Secrets Operator + Lockbox, NetworkPolicy между namespace'ами, OPA/Gatekeeper.

## Стоимость

Минимальный конфиг (1 worker `2 vCPU 50%`, 8 GB, 64 GB SSD, 1 NLB):

| Компонент | ~₽/мес |
|---|---|
| Compute | 1500 |
| Disk SSD | 400 |
| Load Balancer + 2 IP | 1000 |
| Container Registry (до 5 GB) | 0 |
| DNS / KMS / YDB / Object Storage | 50 |
| **Итого минимум** | **~3000** |

При росте — линейно по нодам.
