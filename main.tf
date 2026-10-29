module "barramento" {
  source = "./modules/barramento"
}

module "notificacoes" {
  source = "./modules/notificacoes"

  email_plantao       = var.email_plantao
  account_id          = data.aws_caller_identity.atual.account_id
  bus_name            = module.barramento.bus_name
  regra_urgentes_name = module.barramento.regra_urgentes_name
  regra_urgentes_arn  = module.barramento.regra_urgentes_arn
}

module "registrar_chamado" {
  source = "./modules/registrar_chamado"

  source_file = "${path.module}/src/registrar_chamado.py"
  output_path = "${path.module}/build/registrar_chamado.zip"
  bus_name    = module.barramento.bus_name
  bus_arn     = module.barramento.bus_arn
}

module "auditoria" {
  source = "./modules/auditoria"

  source_file          = "${path.module}/src/auditar_chamado.py"
  output_path          = "${path.module}/build/auditar_chamado.zip"
  bus_name             = module.barramento.bus_name
  regra_auditoria_name = module.barramento.regra_auditoria_name
  regra_auditoria_arn  = module.barramento.regra_auditoria_arn
}

module "api" {
  source = "./modules/api"

  lambda_invoke_arn    = module.registrar_chamado.invoke_arn
  lambda_function_name = module.registrar_chamado.function_name
}

module "budget" {
  source = "./modules/budget"

  email_plantao = var.email_plantao
}
