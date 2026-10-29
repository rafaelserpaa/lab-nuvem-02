# Guia de uso — passo a passo

Este guia assume que você já leu o [README.md](README.md) e quer subir a
infraestrutura, testar o fluxo de ponta a ponta e, eventualmente,
desmontar tudo de novo.

## 1. Pré-requisitos

1. **Terraform ≥ 1.5.0** instalado (`terraform version`).
2. **AWS CLI configurado** com credenciais que tenham permissão para criar
   Lambda, IAM, EventBridge, SNS, API Gateway e Budgets:
   ```bash
   aws sts get-caller-identity
   ```
   Se esse comando retornar sua conta/usuário, as credenciais estão
   prontas para o Terraform usar (ele lê o mesmo perfil da AWS CLI).
3. Um **e-mail de plantão** válido — é nele que você vai confirmar a
   inscrição no SNS e receber os alertas de orçamento e de chamados
   urgentes.

## 2. Configurar as variáveis

O projeto tem duas variáveis (ver [variables.tf](variables.tf)):

| Variável | Obrigatória | Padrão | Descrição |
|---|---|---|---|
| `email_plantao` | sim | — | E-mail que recebe chamados urgentes e alertas de orçamento |
| `regiao` | não | `us-east-1` | Região AWS onde tudo é criado |

Crie (ou edite) o arquivo `terraform.tfvars` na raiz do projeto — ele **não
é versionado** (está no `.gitignore`), então cada pessoa usa o próprio
e-mail:

```hcl
# terraform.tfvars
email_plantao = "seu-email@exemplo.com"
```

## 3. Inicializar o Terraform

```bash
terraform init
```

Isso baixa os providers `hashicorp/aws` (~> 5.0) e `hashicorp/archive`
(~> 2.4) e inicializa os 6 módulos em [modules/](modules/).

## 4. Revisar o plano

```bash
terraform plan
```

Confira na saída:
- 1 API HTTP, 1 integração, 1 rota, 1 stage;
- 1 event bus + 2 regras (`urgentes`, `auditoria`);
- 2 funções Lambda (`registrar-chamado`, `auditar-chamado`) com suas roles,
  policies e log groups;
- 1 tópico SNS com assinatura por e-mail e policy;
- 1 orçamento mensal (`aws_budgets_budget`).

Nenhum recurso é criado nesse passo — é só uma simulação.

## 5. Aplicar

```bash
terraform apply
```

Confirme com `yes`. Ao final, o Terraform imprime os outputs (ver
[outputs.tf](outputs.tf)):

- `url_api` — invoke URL base da API;
- `endpoint_chamados` — `url_api` + `/chamados` (o endpoint que você vai
  chamar);
- `arn_topico` — ARN do tópico SNS;
- `policy_publicar_manutencao` — JSON da policy de menor privilégio usada
  pela Lambda `registrar_chamado` (útil para documentação/entrega).

> **Confirme a inscrição por e-mail.** A AWS manda um e-mail de
> "AWS Notification - Subscription Confirmation" para `email_plantao`.
> Sem clicar em **Confirm subscription**, você não recebe os alertas de
> chamados urgentes nem os de orçamento.

## 6. Testar o fluxo

### 6.1 Registrar um chamado (caminho feliz)

```bash
ENDPOINT=$(terraform output -raw endpoint_chamados)

curl -i -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
        "local": "Bloco B - sala 12",
        "categoria": "eletrica",
        "descricao": "Tomada sem energia",
        "urgente": false
      }'
```

Resposta esperada: `202 Accepted` com `{"id": "...", "status": "registrado"}`.

### 6.2 Registrar um chamado urgente

Repita com `"urgente": true`. Além do `202`, em alguns segundos chega um
e-mail no `email_plantao` avisando sobre o chamado (via SNS, disparado pela
regra `urgentes`).

### 6.3 Testar a validação (caminho de erro)

```bash
curl -i -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{"local": "", "categoria": "pintura", "urgente": "sim"}'
```

Resposta esperada: `400` com a lista de erros (`local` vazio, `categoria`
fora da lista permitida, `urgente` não é booleano).

### 6.4 Conferir a trilha de auditoria

Todo chamado registrado — urgente ou não — também passa pela Lambda
`auditar-chamado`. Veja os logs dela:

```bash
aws logs tail /aws/lambda/auditar-chamado --since 10m --follow
```

Você deve ver uma linha JSON por chamado, com `eventId`, `tipo`, `origem` e
o `detail` completo do chamado.

Para ver os logs da própria função que recebe a requisição:

```bash
aws logs tail /aws/lambda/registrar-chamado --since 10m --follow
```

## 7. Acompanhar custos

O módulo [modules/budget/](modules/budget/) cria um orçamento mensal de
US$ 25 (`aws_budgets_budget.mensal`). Você recebe e-mail quando:

- o gasto **real** do mês passa de **80%** do limite (US$ 20), ou
- o gasto **previsto** para o mês passa de **100%** do limite (US$ 25).

Não é preciso fazer nada além de confirmar a inscrição do SNS (passo 5) —
o budget usa `subscriber_email_addresses` diretamente, sem SNS.

## 8. Desmontar tudo

Quando terminar os testes, evite custos residuais:

```bash
terraform destroy
```

Confirme com `yes`. Isso remove, nessa ordem lógica, a API, as Lambdas e
suas roles/log groups, o tópico SNS e suas assinaturas/policy, o
EventBridge (bus + regras) e o orçamento.

## Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| `curl` retorna `403` ou `Forbidden` | Rota/stage ainda propagando, ou URL errada | Confirme com `terraform output endpoint_chamados`; espere alguns segundos após o `apply` |
| Não chega e-mail de chamado urgente | Inscrição do SNS não confirmada | Procure o e-mail "Subscription Confirmation" (inclusive em spam) e clique em confirmar |
| `apply` falha em `aws_budgets_budget` | Conta sem Cost Explorer habilitado ou sem permissão de `budgets:*` | Habilite o Cost Explorer na conta e confira a policy do usuário/role usado pelo Terraform |
| Erro de `archive_file` não encontra o `.py` | Rodando `terraform` fora da raiz do projeto | Sempre execute os comandos a partir da raiz (onde está o `main.tf`) |
| Mudança inesperada nas Lambdas a cada `plan` | Código-fonte em `src/*.py` foi alterado | Esperado: o hash do zip (`source_code_hash`) muda e o Terraform recria a função com o novo código |

## Variáveis de referência rápida

```hcl
# terraform.tfvars
email_plantao = "plantao@exemplo.com"
# regiao     = "us-east-1"   # opcional, já é o padrão
```

```bash
terraform init
terraform plan
terraform apply
terraform output                 # ver todos os outputs
terraform output -raw endpoint_chamados
terraform destroy                # ao final dos testes
```
