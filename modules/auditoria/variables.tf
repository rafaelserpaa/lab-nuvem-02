variable "source_file" {
  description = "Caminho do código-fonte da função."
  type        = string
}

variable "output_path" {
  description = "Caminho do zip gerado para o deploy."
  type        = string
}

variable "bus_name" {
  description = "Nome do barramento de eventos."
  type        = string
}

variable "regra_auditoria_name" {
  description = "Nome da regra de auditoria."
  type        = string
}

variable "regra_auditoria_arn" {
  description = "ARN da regra de auditoria (autorizada a invocar a função)."
  type        = string
}
