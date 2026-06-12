# 🏗️ Insurance Analytics Platform — Terraform Edition

## Repositório Educacional: De Engenheiro Pleno a Sênior

[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazonaws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📖 A História por trás deste projeto

Era uma segunda-feira qualquer quando Renata, engenheira de dados plena em uma consultoria, recebeu um chamado urgente: a **SeguraTudo**, uma seguradora de médio porte, precisava responder ao regulador em 5 dias — *"Qual o índice de sinistralidade por linha de negócio nos últimos 12 meses?"*

Parecia simples. Não era.

Os dados de apólices viviam no **Guidewire**. Os sinistros, no **Duck Creek**. O financeiro, no **SAP**. Cada sistema exportava CSVs em formatos diferentes — datas como `01/15/2024` em um, `2024-01-15` no outro. O campo de prêmio vinha como `"R$ 15.000,00"` (string com moeda) num lugar e `15000.00` (decimal) em outro. O campo que unia tudo se chamava `PolicyNo` em um e `POLICY_NUMBER` no outro.

Renata tentou resolver no Excel. Fez VLOOKUP, tentou cruzar 500 mil linhas. O Excel travou. Pediu ajuda à TI — que agendou a extração para a semana seguinte. O prazo do regulador já teria passado.

**Aquele dia, Renata prometeu a si mesma: nunca mais.**

Ela estudou o [AWS InsuranceLake Workshop](https://catalog.workshops.aws/workshops/0a85653e-07e9-41a8-960a-2d1bb592331b/en-US), entendeu a arquitetura, e construiu um pipeline que resolve em **5 minutos** o que antes levava **3 semanas**. Mas fez mais do que copiar comandos do workshop — ela entendeu o *porquê* de cada decisão, converteu de CDK para Terraform (o padrão da consultoria), documentou tudo, e expandiu com cenários reais.

**Seis meses depois, Renata foi promovida a Sênior.**

Não porque decorou serviços AWS. Porque sabia explicar *por que* escolheu Step Functions ao invés de Airflow, *quando* DynamoDB é melhor que S3 para lookups, e *como* o Loss Ratio calculado automaticamente muda a tomada de decisão do CFO.

---

## 🎯 Este repositório é a jornada da Renata — para você seguir.

O objetivo é transformar um workshop de 3 horas (que seria esquecido em uma semana) em um **programa de formação** que produz engenheiros seniores capazes de:

- **Entender o problema** antes de escrever código
- **Projetar** pipelines ETL serverless na AWS
- **Implementar** infraestrutura como código com Terraform
- **Decidir** com justificativa de trade-offs (não por moda)
- **Expandir** soluções com novos casos de uso
- **Apresentar** e defender decisões tecnicamente para stakeholders

---

## 📌 Sobre este Repositório

Este é um **repositório educacional** que reimplementa a arquitetura do [AWS InsuranceLake](https://github.com/aws-solutions-library-samples/aws-insurancelake-etl) usando **Terraform** (ao invés do CDK original), com documentação em português voltada para **engenheiros de dados que querem dar o próximo passo**.

O conteúdo não foi criado do zero. É baseado no excelente material open-source da AWS e adaptado com:
- Conversão de CDK (Python) para Terraform (HCL)
- Documentação didática em português com storytelling
- Explicações de decisões arquiteturais e trade-offs
- Casos de uso expandidos para portfólio profissional
- Mapa mental e raciocínio de negócio para entendimento profundo

### Boas Práticas aplicadas neste projeto

| Prática | Como foi aplicada |
|---|---|
| **Understand before building** | Pasta `reasoning_case/` com problema de negócio, glossário, fluxo |
| **Infrastructure as Code** | Terraform modularizado com environments separados |
| **Separation of Concerns** | Módulos por domínio: s3, glue, dynamodb, step-functions |
| **Documentation as Code** | ADRs, deploy guide, e docs versionados junto com o código |
| **Security by Default** | KMS encryption, IAM least privilege, public access blocked |
| **Cost Awareness** | Lifecycle policies, pay-per-request DynamoDB, estimativa documentada |
| **Observability** | CloudWatch logs, SNS notifications, job audit trail |
| **Reproducibility** | Dados de exemplo, configs versionadas, terraform plan previsível |
| **Progressive Learning** | Do problema de negócio → arquitetura → código → expansão |

---

## 📚 Referências e Créditos

Este repositório é **baseado integralmente** nos seguintes materiais oficiais da AWS:

| Recurso | Link |
|---|---|
| **InsuranceLake Deep Dive Workshop** | https://catalog.workshops.aws/workshops/0a85653e-07e9-41a8-960a-2d1bb592331b/en-US |
| **InsuranceLake ETL (GitHub)** | https://github.com/aws-solutions-library-samples/aws-insurancelake-etl |
| **InsuranceLake Infrastructure (GitHub)** | https://github.com/aws-solutions-library-samples/aws-insurancelake-infrastructure |
| **Documentação Oficial InsuranceLake** | https://aws-solutions-library-samples.github.io/aws-insurancelake-etl/ |
| **AWS Solutions: Modern Insurance Data Lakes** | https://aws.amazon.com/solutions/guidance/modern-insurance-data-lakes-on-aws/ |
| **Well-Architected FSI Lens - Insurance Lake** | https://docs.aws.amazon.com/wellarchitected/latest/financial-services-industry-lens/insurance-lake.html |

> ⚠️ Este repositório NÃO é um produto oficial da AWS. É um material educacional derivado de fontes open-source (licença MIT-0) com valor agregado em documentação, Terraform e didática.

---

## 🧭 Como Seguir esta Jornada (Passo a Passo)

A Renata não fez tudo de uma vez. Ela seguiu uma sequência que respeita como o cérebro aprende:

```
SEMANA 1 — ENTENDER
━━━━━━━━━━━━━━━━━━━
📂 reasoning_case/README.md          → "Qual problema estou resolvendo?"
📂 reasoning_case/glossario-seguros  → "O que significam esses termos?"
📂 reasoning_case/fluxo-negocio      → "Como uma seguradora ganha dinheiro?"
📂 reasoning_case/jornada-dado       → "O que acontece com UM dado no pipeline?"

SEMANA 2 — PROJETAR
━━━━━━━━━━━━━━━━━━━
📂 docs/architecture-decisions.md    → "Por que essas escolhas?"
📂 docs/terraform-vs-cdk.md          → "Por que Terraform e não CDK?"
📂 reasoning_case/mapa-mental        → "Como tudo se conecta?"

SEMANA 3 — IMPLEMENTAR
━━━━━━━━━━━━━━━━━━━━━━
📂 terraform/                        → "terraform init → plan → apply"
📂 sample-data/                      → "Carregar dados e ver o pipeline rodar"
📂 docs/deploy-guide.md              → "Passo a passo do deploy"

SEMANA 4+ — EXPANDIR
━━━━━━━━━━━━━━━━━━━━
📂 reasoning_case/user-cases-expandidos → "Agora eu crio os meus cenários"
```

Cada semana constrói sobre a anterior. Se pular direto para o código, vai funcionar — mas não vai aprender. Se seguir a sequência, vai poder explicar cada decisão numa apresentação ou entrevista.

---

## 🏛️ Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                    INSURANCE ANALYTICS PLATFORM                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐      │
│  │  SOURCE  │───▶│ COLLECT  │───▶│ CLEANSE  │───▶│ CONSUME  │      │
│  │ SYSTEMS  │    │   (S3)   │    │  (Glue)  │    │ (Athena) │      │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘      │
│                       │                                   │          │
│                       ▼                                   ▼          │
│                 ┌──────────┐                       ┌──────────┐     │
│                 │  Lambda  │                       │QuickSight│     │
│                 │ (Trigger)│                       │   (BI)   │     │
│                 └──────────┘                       └──────────┘     │
│                       │                                              │
│                       ▼                                              │
│                 ┌──────────┐                                        │
│                 │   Step   │                                        │
│                 │Functions │                                        │
│                 └──────────┘                                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Serviços AWS utilizados:**
- Amazon S3 (armazenamento em 3 camadas)
- AWS Glue (ETL com PySpark)
- AWS Step Functions (orquestração)
- AWS Lambda (trigger e automação)
- Amazon DynamoDB (lookups e auditoria)
- Amazon Athena (queries SQL)
- AWS KMS (encryption)
- Amazon CloudWatch (monitoramento)

---

## 📁 Estrutura do Repositório

```
.
├── README.md                          ← Você está aqui
├── LICENSE
├── .gitignore
│
├── terraform/                         ← Infraestrutura como Código
│   ├── environments/
│   │   ├── dev/                       ← Configuração do ambiente Dev
│   │   └── prod/                      ← Configuração do ambiente Prod
│   ├── modules/
│   │   ├── s3-data-lake/              ← Buckets S3 (collect, cleanse, consume)
│   │   ├── glue-etl/                  ← Glue Jobs, Catalog, Crawlers
│   │   ├── step-functions/            ← State Machine de orquestração
│   │   ├── lambda-trigger/            ← Lambda para trigger S3
│   │   ├── dynamodb/                  ← Tabelas de lookup e auditoria
│   │   ├── athena/                    ← Workgroup e named queries
│   │   └── security/                  ← KMS, IAM roles, policies
│   └── shared/
│       └── variables.tf               ← Variáveis globais compartilhadas
│
├── glue-scripts/                      ← Scripts PySpark dos Glue Jobs
│   ├── collect_to_cleanse.py
│   ├── cleanse_to_consume.py
│   └── lib/
│       ├── transformation-spec/       ← Configs de transformação (JSON)
│       ├── dq-rules/                  ← Regras de Data Quality (JSON)
│       └── transformation-sql/        ← Spark SQL e Athena SQL
│
├── lambda/                            ← Código das Lambda functions
│   ├── state_machine_trigger/
│   └── etl_job_auditor/
│
├── sample-data/                       ← Dados de exemplo para testes
│   ├── policy-data.csv
│   ├── claim-data.csv
│   └── lookup-data.json
│
├── reasoning_case/                    ← Entendimento do problema de negócio
│   ├── README.md                      ← Problema central explicado
│   ├── mapa-mental.md                 ← Mapas mentais visuais
│   ├── fluxo-negocio.md              ← Como uma seguradora opera
│   ├── glossario-seguros.md          ← Termos do setor
│   ├── jornada-dado.md               ← Rastreio de um dado pelo pipeline
│   └── user-cases-expandidos.md      ← 9 cenários para portfólio
│
├── docs/                              ← Documentação técnica
│   ├── architecture-decisions.md      ← ADRs (decisões arquiteturais)
│   ├── terraform-vs-cdk.md           ← Por que Terraform ao invés de CDK
│   └── deploy-guide.md              ← Guia de deploy passo a passo
│
└── scripts/                           ← Scripts auxiliares
    ├── deploy.sh                      ← Deploy automatizado
    ├── destroy.sh                     ← Cleanup de recursos
    └── load-sample-data.sh           ← Carga de dados de exemplo
```

---

## 🚀 Quick Start

### Pré-requisitos

- AWS CLI configurado com credenciais
- Terraform >= 1.5
- Python 3.9+

### Deploy

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Carregar dados de exemplo

```bash
./scripts/load-sample-data.sh dev
```

### Consultar resultados

```sql
-- No Amazon Athena (workgroup: insurancelake)
SELECT * FROM syntheticgeneraldata_consume.policydata LIMIT 100;
```

---

## 🎓 Para quem é este repositório?

| Perfil | Como usar | O que vai ganhar |
|---|---|---|
| **Engenheiro Pleno → Sênior** | Siga a jornada semana a semana | Portfólio + profundidade técnica + visão de negócio |
| **Arquiteto de Soluções** | Analise `docs/architecture-decisions.md` | Referência de ADRs para projetos de data lake |
| **Tech Lead** | Use como template + adapte ao cliente | Acelerador de onboarding do time |
| **Estudante** | Fork + implemente os user cases expandidos | Projeto completo para portfólio GitHub |

### O que diferencia quem usa este material

| O que um Pleno faz | O que um Sênior faz |
|---|---|
| "Usei Glue e S3" | "Escolhi Glue porque é serverless e custa $0.44/DPU-hour vs EMR que cobra por hora de cluster, mesmo parado" |
| "Fiz o pipeline funcionar" | "O pipeline processa 500K linhas em 3 minutos, com data quality rules que quarentenam dados inválidos automaticamente" |
| "Converti de CDK para Terraform" | "Converti para Terraform porque 90% dos clientes enterprise já usam, e a modularização permite reutilizar o módulo DynamoDB em outros projetos" |
| "Calculei o Loss Ratio" | "O Loss Ratio automatizado permite ao CFO identificar que o ramo Business está em 81% e precisa de repricing antes do fechamento trimestral" |

---

## 🔄 CDK Original vs. Terraform (Este Repo)

| Aspecto | CDK Original | Este Repo (Terraform) |
|---|---|---|
| Linguagem IaC | Python | HCL |
| Multi-cloud ready | Não (AWS only) | Conceitos portáveis |
| Curva de aprendizado | Precisa saber CDK + Python | Terraform é padrão de mercado |
| State management | CloudFormation | Terraform State (S3 backend) |
| Modularização | CDK Constructs | Terraform Modules |
| Documentação | Inglês técnico | Português didático |
| Foco | Produção | Educação + Produção |

---

## 📊 Custo Estimado

Executando o pipeline com dados de exemplo:
- **Glue Jobs:** ~$3.50 (8 DPU-hours)
- **S3:** < $0.01
- **DynamoDB:** < $0.01
- **Athena:** < $0.05
- **Total: < $4.00**

> ⚠️ Lembre-se de executar `terraform destroy` após estudar para evitar custos contínuos.

---

## 📝 Licença

Este repositório é distribuído sob licença MIT. O código original do InsuranceLake está sob licença MIT-0 da Amazon.

---

## 🤝 Contribuições

Contribuições são bem-vindas! Especialmente:
- Novos user cases para o setor de seguros
- Melhorias na documentação
- Correções e otimizações no Terraform
- Traduções de documentação técnica

---

## 💬 A moral da história

A Renata não se tornou Sênior porque sabia mais serviços AWS que os colegas. Ela se tornou Sênior porque:

1. **Entendeu o negócio** — sabia o que é Loss Ratio sem precisar perguntar ao gestor
2. **Justificou decisões** — não apenas "funciona", mas "funciona por esse motivo, e a alternativa seria X com Y trade-off"
3. **Pensou em escala** — "e se forem 100 tabelas? e se o regulador pedir outro corte?"
4. **Documentou** — quem pegasse o projeto depois dela conseguiria entender e evoluir
5. **Expandiu** — não parou no workshop, criou cenários novos e mostrou autonomia

Este repositório é o mapa que ela seguiu. Agora é o seu.

---

*Criado como material educacional para formação de engenheiros de dados.*
*Baseado no [AWS InsuranceLake](https://github.com/aws-solutions-library-samples/aws-insurancelake-etl) — um excelente solution accelerator open-source da AWS.*
