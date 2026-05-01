output "network_id" {
  value = yandex_vpc_network.this.id
}

output "subnet_ids" {
  description = "Map zone → subnet_id"
  value       = { for z, s in yandex_vpc_subnet.this : z => s.id }
}

output "k8s_master_sg_id" {
  value = yandex_vpc_security_group.k8s_master.id
}

output "k8s_nodes_sg_id" {
  value = yandex_vpc_security_group.k8s_nodes.id
}
