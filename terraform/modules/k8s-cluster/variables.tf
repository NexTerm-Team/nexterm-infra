variable "folder_id" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "network_id" {
  type = string
}

variable "master_zone" {
  description = "Зона zonal-master'а. Также используется для размещения нод."
  type        = string
}

variable "master_subnet_id" {
  description = "ID subnet'а в master_zone"
  type        = string
}

variable "master_security_group_id" {
  type = string
}

variable "nodes_security_group_id" {
  type = string
}

variable "k8s_version" {
  description = "Версия k8s в формате MAJOR.MINOR (последний patch выбирается release-channel)"
  type        = string
  default     = "1.30"
}

variable "cluster_ipv4_range" {
  description = "Pod CIDR"
  type        = string
  default     = "10.96.0.0/16"
}

variable "service_ipv4_range" {
  description = "Service CIDR"
  type        = string
  default     = "10.97.0.0/16"
}

variable "node_cores" {
  type    = number
  default = 2
}

variable "node_memory_gb" {
  type    = number
  default = 8
}

# core_fraction = 50 даёт 50% guaranteed performance (s2.small аналог).
# Для critical workload — 100. Для тестов — 20 (s2.micro, ещё дешевле).
variable "node_core_fraction" {
  type    = number
  default = 50
}

variable "node_disk_size_gb" {
  type    = number
  default = 64
}

variable "autoscale_min" {
  type    = number
  default = 1
}

variable "autoscale_max" {
  type    = number
  default = 3
}

variable "autoscale_initial" {
  type    = number
  default = 1
}
