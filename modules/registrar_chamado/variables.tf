variable "source_file" {
  description = "Caminho do código-fonte da função."
  type        = string
}

variable "output_path" {
  description = "Caminho do zip gerado para o deploy."
  type        = string
}

variable "bus_name" {
  description = "Nome do barramento onde a função publica os eventos."
  type        = string
}

variable "bus_arn" {
  description = "ARN do barramento (escopo da policy de menor privilégio)."
  type        = string
}
