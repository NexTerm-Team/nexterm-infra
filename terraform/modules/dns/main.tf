# Публичная DNS-зона. NS-делегирование делается ВРУЧНУЮ у регистратора —
# смотри outputs.name_servers и пропиши их в панели RU-Center.
resource "yandex_dns_zone" "public" {
  name        = replace(var.zone_name, ".", "-")
  description = "Публичная зона ${var.zone_name}"
  folder_id   = var.folder_id

  zone   = "${var.zone_name}."
  public = true
}

# Базовые записи.
# A-запись для apex (@) — на публичный IP YC ALB / NLB. До его создания
# временно ставим placeholder; после установки ingress-controller'а
# обновляется через переменную apex_a_record.
resource "yandex_dns_recordset" "apex_a" {
  count = var.apex_a_record == "" ? 0 : 1

  zone_id = yandex_dns_zone.public.id
  name    = "${var.zone_name}."
  type    = "A"
  ttl     = 300
  data    = [var.apex_a_record]
}

resource "yandex_dns_recordset" "www" {
  count = var.apex_a_record == "" ? 0 : 1

  zone_id = yandex_dns_zone.public.id
  name    = "www.${var.zone_name}."
  type    = "CNAME"
  ttl     = 300
  data    = ["${var.zone_name}."]
}

# Дополнительные записи передаются через переменную (TXT для SPF/DMARC, MX и т.д.)
resource "yandex_dns_recordset" "extra" {
  for_each = var.extra_records

  zone_id = yandex_dns_zone.public.id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  data    = each.value.data
}
