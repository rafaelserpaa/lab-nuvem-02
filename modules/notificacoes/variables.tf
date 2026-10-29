variable "email_plantao" {
  description = "E-mail que recebe os chamados urgentes."
  type        = string
}

variable "account_id" {
  description = "Conta AWS dona do tópico."
  type        = string
}

variable "bus_name" {
  description = "Nome do barramento de eventos."
  type        = string
}

variable "regra_urgentes_name" {
  description = "Nome da regra de chamados urgentes."
  type        = string
}

variable "regra_urgentes_arn" {
  description = "ARN da regra de chamados urgentes (autorizada a publicar no tópico)."
  type        = string
}
