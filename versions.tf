terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.regiao

  default_tags {
    tags = {
      Projeto       = "central-chamados"
      Disciplina    = "Arquitetura de Software Nativa em Nuvem"
      GerenciadoPor = "terraform"
    }
  }
}

data "aws_caller_identity" "atual" {}