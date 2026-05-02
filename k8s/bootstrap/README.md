# k8s bootstrap — что нужно поставить в кластер один раз

Все эти компоненты ставятся через Helm. Порядок важен.

## Предварительно

```bash
# Получить kubeconfig (после успешного terraform apply prod)
yc managed-kubernetes cluster get-credentials nexterm-prod-k8s --external --force

# Проверить
kubectl get nodes
```

## 1. NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  -f k8s/bootstrap/ingress-nginx/values.yaml
```

После установки — узнать публичный IP LoadBalancer'а:

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Затем:
1. Прописать этот IP в `terraform/environments/prod/main.tf` → `module.dns.apex_a_record`.
2. `terraform apply` ещё раз — создаст A-запись `nexterm.ru` → IP.

## 2. cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set installCRDs=true \
  -f k8s/bootstrap/cert-manager/values.yaml
```

## 3. ClusterIssuer для Let's Encrypt

После установки cert-manager и **только после делегирования NS на YC** (LE проверяет
домен через HTTP-01 challenge — до делегирования валидация не пройдёт):

```bash
kubectl apply -f k8s/bootstrap/cert-manager/cluster-issuer.yaml
```

Проверить:

```bash
kubectl get clusterissuer
# letsencrypt-prod   True   ...
```

## 4. Готово

Можно деплоить приложения через `helm upgrade ... k8s/apps/<name>` — Ingress
автоматически получит TLS-сертификат от Let's Encrypt при первом обращении.
