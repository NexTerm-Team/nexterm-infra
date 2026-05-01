provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
  # Аутентификация:
  #   - локально: YC_TOKEN env (oauth) или YC_SERVICE_ACCOUNT_KEY_FILE
  #   - в CI: WIF — через `yc iam create-token --workload-identity-federation` и YC_TOKEN
}

# ============================================================================
# Network
# ============================================================================
module "network" {
  source = "../../modules/network"

  folder_id   = var.folder_id
  name_prefix = var.name_prefix

  # Subnet'ы заведены под все три зоны (на будущее), активно используется одна.
}

# ============================================================================
# Container Registry
# ============================================================================
module "container_registry" {
  source = "../../modules/container-registry"

  folder_id   = var.folder_id
  name_prefix = var.name_prefix
}

# ============================================================================
# Managed Kubernetes (zonal)
# ============================================================================
module "k8s" {
  source = "../../modules/k8s-cluster"

  folder_id   = var.folder_id
  name_prefix = var.name_prefix
  network_id  = module.network.network_id

  master_zone              = var.default_zone
  master_subnet_id         = module.network.subnet_ids[var.default_zone]
  master_security_group_id = module.network.k8s_master_sg_id
  nodes_security_group_id  = module.network.k8s_nodes_sg_id

  # Параметры по умолчанию: 2 vCPU(50%), 8 GB, autoscale 1..3 — см. модуль.
}

# ============================================================================
# DNS
# ============================================================================
module "dns" {
  source = "../../modules/dns"

  folder_id = var.folder_id
  zone_name = var.domain

  # apex_a_record заполнится после установки nginx-ingress и появления LB-IP.
  # Первый apply — пусто, второй — IP из output'а ingress-controller'а.
  apex_a_record = ""
}

# ============================================================================
# Workload Identity Federation для GitHub Actions
# ============================================================================
module "wif" {
  source = "../../modules/wif"

  folder_id             = var.folder_id
  name_prefix           = var.name_prefix
  github_owner          = var.github_owner
  container_registry_id = module.container_registry.registry_id
  repos                 = var.ci_repos
}
