# ============================================================================
# Service account для самого кластера (control plane → API YC)
# ============================================================================
resource "yandex_iam_service_account" "cluster" {
  name        = "${var.name_prefix}-cluster-sa"
  description = "SA для k8s control plane"
  folder_id   = var.folder_id
}

# k8s.clusters.agent — минимально необходимая роль для master'а.
resource "yandex_resourcemanager_folder_iam_member" "cluster_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.cluster.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "cluster_lb_admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.cluster.id}"
}

# ============================================================================
# Service account для node-группы (используется kubelet'ом, pull образов из CR)
# ============================================================================
resource "yandex_iam_service_account" "nodes" {
  name        = "${var.name_prefix}-nodes-sa"
  description = "SA для k8s worker nodes (pull из Container Registry)"
  folder_id   = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "nodes_cr_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.nodes.id}"
}

# ============================================================================
# KMS key для envelope encryption секретов в etcd
# ============================================================================
resource "yandex_kms_symmetric_key" "k8s" {
  name              = "${var.name_prefix}-k8s-secrets"
  description       = "KMS-ключ для шифрования k8s Secrets at-rest"
  folder_id         = var.folder_id
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # раз в год
}

resource "yandex_kms_symmetric_key_iam_member" "k8s_encrypter" {
  symmetric_key_id = yandex_kms_symmetric_key.k8s.id
  role             = "kms.keys.encrypterDecrypter"
  member           = "serviceAccount:${yandex_iam_service_account.cluster.id}"
}

# ============================================================================
# Кластер
# ============================================================================
resource "yandex_kubernetes_cluster" "this" {
  name        = "${var.name_prefix}-k8s"
  description = "Managed k8s для экосистемы nexterm"
  folder_id   = var.folder_id

  network_id = var.network_id

  master {
    version = var.k8s_version

    # Zonal master — single zone, ~0 ₽/мес. Для HA → regional с тремя locations.
    zonal {
      zone      = var.master_zone
      subnet_id = var.master_subnet_id
    }

    public_ip = true

    security_group_ids = [var.master_security_group_id]

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "03:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.cluster.id
  node_service_account_id = yandex_iam_service_account.nodes.id

  release_channel = "STABLE"

  kms_provider {
    key_id = yandex_kms_symmetric_key.k8s.id
  }

  cluster_ipv4_range = var.cluster_ipv4_range
  service_ipv4_range = var.service_ipv4_range

  depends_on = [
    yandex_resourcemanager_folder_iam_member.cluster_agent,
    yandex_resourcemanager_folder_iam_member.cluster_lb_admin,
    yandex_resourcemanager_folder_iam_member.nodes_cr_puller,
    yandex_kms_symmetric_key_iam_member.k8s_encrypter,
  ]
}

# ============================================================================
# Node group
# ============================================================================
resource "yandex_kubernetes_node_group" "this" {
  cluster_id  = yandex_kubernetes_cluster.this.id
  name        = "${var.name_prefix}-workers"
  description = "Основной пул worker-нод"
  version     = var.k8s_version

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = true # auto-assigned public IP — дёшево, без NAT Gateway
      subnet_ids         = [var.master_subnet_id]
      security_group_ids = [var.nodes_security_group_id]
    }

    resources {
      cores         = var.node_cores
      memory        = var.node_memory_gb
      core_fraction = var.node_core_fraction
    }

    boot_disk {
      type = "network-ssd"
      size = var.node_disk_size_gb
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    auto_scale {
      min     = var.autoscale_min
      max     = var.autoscale_max
      initial = var.autoscale_initial
    }
  }

  allocation_policy {
    location {
      zone = var.master_zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "03:00"
      duration   = "3h"
    }
  }
}
