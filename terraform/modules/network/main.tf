resource "yandex_vpc_network" "this" {
  name        = "${var.name_prefix}-vpc"
  description = "VPC для всей экосистемы nexterm"
  folder_id   = var.folder_id
}

# Subnet'ы заведены под все три зоны на будущее (multi-AZ HA),
# но сейчас используется только subnet в default-зоне (см. var.active_zones).
resource "yandex_vpc_subnet" "this" {
  for_each = toset(var.zones)

  name           = "${var.name_prefix}-subnet-${each.key}"
  description    = "Subnet для k8s worker nodes в зоне ${each.key}"
  folder_id      = var.folder_id
  zone           = each.key
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [var.subnet_cidrs[each.key]]
}

# ============================================================================
# Security group для master k8s — обязательная по требованию YC.
# ============================================================================
resource "yandex_vpc_security_group" "k8s_master" {
  name        = "${var.name_prefix}-k8s-master-sg"
  description = "SG для control-plane managed k8s"
  folder_id   = var.folder_id
  network_id  = yandex_vpc_network.this.id

  # Приём health-check от LB YC (обязательное правило).
  ingress {
    protocol          = "TCP"
    description       = "health checks от YC"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  # Доступ к API k8s из Интернета (kubectl). Можно сузить по IP позже.
  ingress {
    protocol       = "TCP"
    description    = "k8s API public"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }
  ingress {
    protocol       = "TCP"
    description    = "k8s API internal"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  # Внутрикластерный трафик master ↔ nodes.
  ingress {
    protocol          = "ANY"
    description       = "self-traffic между master и nodes"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  egress {
    protocol       = "ANY"
    description    = "egress всё"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# ============================================================================
# Security group для worker nodes.
# ============================================================================
resource "yandex_vpc_security_group" "k8s_nodes" {
  name        = "${var.name_prefix}-k8s-nodes-sg"
  description = "SG для k8s worker nodes"
  folder_id   = var.folder_id
  network_id  = yandex_vpc_network.this.id

  ingress {
    protocol          = "ANY"
    description       = "self-traffic между нодами"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "TCP"
    description       = "health checks от YC LB"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  # Входящий трафик от ingress-controller'ов через NodePort (для MetalLB или ALB
  # это не нужно, но для NLB через nginx-ingress — да). Сужаем когда определимся.
  ingress {
    protocol       = "TCP"
    description    = "NodePort range"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  ingress {
    protocol       = "ICMP"
    description    = "ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "egress всё"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# ============================================================================
# Cross-SG правила: master ↔ nodes
#
# Без них admission webhooks (cert-manager-webhook, ingress-nginx-admission и т.д.)
# не работают: k8s API на master пытается дозвониться до webhook-pod на ноде,
# но SG в YC по умолчанию не пропускает трафик между разными SG.
#
# Делаем через отдельные yandex_vpc_security_group_rule ресурсы, чтобы избежать
# циклической зависимости (если бы ingress-блок одной SG ссылался на ID другой
# SG, и наоборот — terraform не смог бы построить DAG).
# ============================================================================

resource "yandex_vpc_security_group_rule" "master_from_nodes_all" {
  security_group_binding = yandex_vpc_security_group.k8s_master.id
  direction              = "ingress"
  description            = "Весь трафик из SG nodes (admission webhooks, kubelet)"
  protocol               = "ANY"
  from_port              = 0
  to_port                = 65535
  security_group_id      = yandex_vpc_security_group.k8s_nodes.id
}

resource "yandex_vpc_security_group_rule" "nodes_from_master_all" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  description            = "Весь трафик из SG master (kube-apiserver → kubelet, webhook)"
  protocol               = "ANY"
  from_port              = 0
  to_port                = 65535
  security_group_id      = yandex_vpc_security_group.k8s_master.id
}
