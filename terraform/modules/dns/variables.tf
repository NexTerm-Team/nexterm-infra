variable "folder_id" {
  type = string
}

variable "zone_name" {
  description = "Доменное имя без точки в конце, например nexterm.ru"
  type        = string
}

variable "apex_a_record" {
  description = "IP для apex A-записи и www CNAME. Если пусто — записи не создаются (в первый apply ingress-LB ещё не существует)."
  type        = string
  default     = ""
}

variable "extra_records" {
  description = "Дополнительные DNS-записи (MX, TXT, etc)"
  type = map(object({
    name = string
    type = string
    ttl  = number
    data = list(string)
  }))
  default = {}
}
