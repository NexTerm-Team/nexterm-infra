output "zone_id" {
  value = yandex_dns_zone.public.id
}

output "zone_name" {
  value = yandex_dns_zone.public.zone
}

output "name_servers" {
  description = "NS-серверы YC. Пропишите их в панели RU-Center для делегирования зоны."
  value = [
    "ns1.yandexcloud.net.",
    "ns2.yandexcloud.net.",
  ]
}
