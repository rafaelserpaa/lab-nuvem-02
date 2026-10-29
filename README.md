# Central de Chamados — Arquitetura de Software Nativa em Nuvem

Infraestrutura em Terraform de uma central de chamados (manutenção de campus)
orientada a eventos na AWS. Um chamado entra pela API HTTP, é validado e
publicado como evento no EventBridge; a partir daí, dois caminhos
independentes consomem esse evento: um manda os chamados urgentes para o
plantão por e-mail (via SNS) e outro grava uma trilha de auditoria de tudo
que acontece.

> Para o passo a passo de uso (configurar, aplicar, testar), veja o
> [GUIA.md](GUIA.md).

## Arquitetura

```
                         POST /chamados
                               │
                               ▼
                    ┌─────────────────────┐
                    │  API Gateway (HTTP)  │
                    └──────────┬───────────┘
                               │ invoca
                               ▼
                 ┌─────────────────────────┐
                 │ Lambda registrar-chamado │  valida o corpo da
                 │                          │  requisição e publica
                 └──────────────┬───────────┘  o evento
                                 │ events:PutEvents
                                 ▼
                 ┌─────────────────────────────┐
                 │ EventBridge — bus "manutencao" │
                 └───────────┬─────────────┬─────┘
                   regra          regra
                 "urgentes"     "auditoria"
                   │                 │
                   ▼                 ▼
         ┌─────────────────┐ ┌───────────────────────┐
         │ SNS "chamados-  │ │ Lambda auditar-chamado │
         │ urgentes"       │ │ (grava log no          │
         │ → e-mail plantão│ │  CloudWatch Logs)      │
         └─────────────────┘ └───────────────────────┘
```

- **Regra `urgentes`**: casa eventos `ChamadoRegistrado` com
  `detail.urgente = true` e os entrega ao tópico SNS.
- **Regra `auditoria`**: casa *todo* evento com `source = campus.chamados`
  (urgente ou não) e os entrega à Lambda de auditoria.
- As duas regras vivem no mesmo barramento (`manutencao`), não no barramento
  padrão da conta — isso isola os eventos do projeto.

Além do caminho de eventos, há um **orçamento mensal** (AWS Budgets) que
avisa por e-mail quando o gasto do mês passa de 80% (real) ou tende a passar
de 100% (previsto) do limite de US$ 25.

## Organização em módulos

O código raiz (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`) apenas
declara variáveis, o provider e **conecta os módulos** — nenhum recurso da
AWS é criado diretamente na raiz. Cada módulo em [modules/](modules/)
corresponde a uma responsabilidade do sistema:

| Módulo | Responsabilidade | Recursos principais |
|---|---|---|
| [modules/barramento/](modules/barramento/) | Canal de eventos do domínio | `aws_cloudwatch_event_bus`, as regras `urgentes` e `auditoria` |
| [modules/registrar_chamado/](modules/registrar_chamado/) | Recebe e valida o chamado, publica o evento | Lambda, log group, role e policies (logs + `events:PutEvents` restrito ao bus) |
| [modules/notificacoes/](modules/notificacoes/) | Avisa o plantão dos chamados urgentes | Tópico SNS, assinatura por e-mail, policy do tópico, target da regra `urgentes` |
| [modules/auditoria/](modules/auditoria/) | Trilha de auditoria de todo evento | Lambda, log group, role, target da regra `auditoria`, permissão do EventBridge |
| [modules/api/](modules/api/) | Porta de entrada HTTP | API Gateway (HTTP API), integração, rota `POST /chamados`, stage `$default` |
| [modules/budget/](modules/budget/) | Controle de custo | `aws_budgets_budget` mensal com alertas em 80% (real) e 100% (previsto) |

Os módulos são ligados apenas num sentido, sem dependência circular:

```
barramento ──┬──► registrar_chamado ──► api
             ├──► notificacoes
             └──► auditoria
budget (independente)
```

- `barramento` não depende de nada — expõe o nome/ARN do bus e das regras.
- `registrar_chamado` e `auditoria` consomem o barramento (cada um lê a
  regra que lhe interessa) e expõem o que a `api` ou a `notificacoes`
  precisam (invoke ARN da Lambda, ARN da regra).
- `notificacoes` consome o barramento e cria o *target* que liga a regra
  `urgentes` ao tópico SNS.
- `api` só conhece a Lambda `registrar_chamado` (invoke ARN e nome da
  função) — não sabe nada sobre EventBridge, SNS ou auditoria.
- `budget` é independente; só recebe o e-mail do plantão.

## Estrutura de arquivos

```
.
├── main.tf              # chama os 6 módulos e liga as saídas de um às entradas do outro
├── variables.tf         # regiao, email_plantao
├── outputs.tf           # ARN do tópico, URL da API, policy de menor privilégio
├── versions.tf          # provider aws/archive + tags padrão
├── terraform.tfvars     # valores reais das variáveis (não versionado)
├── src/
│   ├── registrar_chamado.py   # valida o corpo e publica ChamadoRegistrado
│   └── auditar_chamado.py     # grava um log por evento recebido
├── build/               # zips gerados pelo archive_file (não versionado)
└── modules/
    ├── barramento/
    ├── registrar_chamado/
    ├── notificacoes/
    ├── auditoria/
    ├── api/
    └── budget/
```

## Funções Lambda

- **`registrar_chamado`** ([src/registrar_chamado.py](src/registrar_chamado.py)):
  recebe o corpo da requisição HTTP, valida `local`, `descricao`,
  `categoria` (uma de `eletrica`, `hidraulica`, `climatizacao`, `limpeza`,
  `ti`) e `urgente` (booleano). Se inválido, responde `400`. Se válido,
  gera um `id` (UUID), publica o evento `ChamadoRegistrado` no bus
  `manutencao` e responde `202`. Se o `PutEvents` falhar, responde `502`.
- **`auditar_chamado`** ([src/auditar_chamado.py](src/auditar_chamado.py)):
  alvo da regra `auditoria`; recebe o envelope completo do EventBridge
  (`id`, `detail-type`, `source`, `time`, `detail`) e grava uma linha de
  log JSON no CloudWatch Logs — serve como trilha de auditoria de tudo que
  passa pelo barramento.

## Requisitos

- Terraform ≥ 1.5.0 (testado com 1.17.1)
- Provider `hashicorp/aws` ~> 5.0 e `hashicorp/archive` ~> 2.4
- Conta AWS na região `us-east-1` (padrão da variável `regiao`)
- Python 3.13 (runtime das Lambdas — só importa para quem for alterar o
  código-fonte; o Terraform empacota o zip sozinho)

Veja o [GUIA.md](GUIA.md) para o passo a passo completo de configuração,
deploy e teste.
