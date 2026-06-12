# Por que Terraform ao invés de CDK?

## Contexto

O projeto original InsuranceLake da AWS usa **CDK (Cloud Development Kit)** em Python. Neste repositório, optamos por **Terraform** (HCL). Aqui está o raciocínio.

## Comparação

| Aspecto | CDK (Original) | Terraform (Este Repo) |
|---|---|---|
| Linguagem | Python | HCL (HashiCorp Configuration Language) |
| Adoção no mercado | Crescente (AWS-only) | Dominante (multi-cloud) |
| Curva de aprendizado | Precisa saber Python + CDK abstractions | HCL é declarativo e direto |
| State management | CloudFormation (gerenciado pela AWS) | Terraform State (S3 backend) |
| Multi-cloud | Não | Sim (AWS, Azure, GCP) |
| Módulos | CDK Constructs (L1, L2, L3) | Terraform Modules (registry público) |
| Plan/Preview | `cdk diff` | `terraform plan` (mais detalhado) |
| Debugging | Stack traces Python + CloudFormation events | `terraform plan` mostra exatamente o que muda |
| CI/CD | CodePipeline (self-mutating) | Qualquer CI (GitHub Actions, GitLab, Jenkins) |
| Comunidade | Menor, AWS-focused | Enorme, multi-cloud |

## Decisão

Para um repositório **educacional** voltado a engenheiros que trabalham em consultorias (como NTT DATA), Terraform é a escolha pragmática porque:

1. **90% dos clientes enterprise usam Terraform** — é a skill mais demandada
2. **Multi-cloud** — o conhecimento porta para Azure e GCP
3. **Transparência** — HCL é declarativo, cada recurso é explícito, fácil de ler e ensinar
4. **Não exige conhecimento de Python para IaC** — separa concerns entre infra e ETL
5. **Mercado de trabalho** — Terraform é requisito em quase toda vaga de DevOps/SRE/Data Engineer Sênior

## Trade-offs aceitos

- Perdemos o **self-mutating pipeline** do CDK Pipelines (podemos compensar com GitHub Actions)
- Perdemos **L3 Constructs** que abstraem patterns complexos (compensamos com módulos bem documentados)
- CDK gera CloudFormation otimizado; Terraform faz API calls diretamente (ambos funcionam)
