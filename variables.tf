variable "regiao" {
  description = "Região da AWS. O roteiro pede us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "email_plantao" {
  description = "E-mail que recebe os chamados urgentes."
  type        = string
}