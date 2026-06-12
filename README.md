# 🏗️ Insurance Analytics Platform — Terraform Edition

## Repositório Educacional: De Engenheiro Pleno a Sênior

[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazonaws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📌 Sobre este Repositório

Este é um **repositório educacional** que reimplementa a arquitetura do [AWS InsuranceLake](https://github.com/aws-solutions-library-samples/aws-insurancelake-etl) usando **Terraform** (ao invés do CDK original), com documentação em português voltada para **engenheiros de dados que querem evoluir de Pleno para Sênior**.

O conteúdo não foi criado do zero. É baseado no excelente material open-source da AWS e adaptado com:
- Conversão de CDK (Python) para Terraform (HCL)
- Documentação didática em português
- Explicações de decisões arquiteturais e trade-offs
- Casos de uso expandidos para portfólio profissional
- Mapa mental e raciocínio de negócio para entendimento profundo

---

## 🎯 Objetivo

Transformar um workshop de 3 horas (que seria esquecido em uma semana) em um **programa de formação** que produz engenheiros seniores capazes de:

- Entender o problema de negócio antes de escrever código
- Projetar pipelines ETL serverless na AWS
- Implementar infraestrutura como código com Terraform
- Tomar decisões arquiteturais com justificativa de trade-offs
- Expandir soluções com novos casos de uso
- Apresentar e defender suas decisões tecnicamente

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

| Perfil | Como usar |
|---|---|
| **Engenheiro Pleno → Sênior** | Estude o `reasoning_case/` primeiro, depois implemente o Terraform |
| **Arquiteto de Soluções** | Analise as decisões em `docs/architecture-decisions.md` |
| **Tech Lead** | Use como template para projetos reais de data lake |
| **Estudante** | Fork e implemente os user cases expandidos como portfólio |

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

*Criado como material educacional para formação de engenheiros de dados.*
*Baseado no [AWS InsuranceLake](https://github.com/aws-solutions-library-samples/aws-insurancelake-etl) — um excelente solution accelerator open-source da AWS.*
