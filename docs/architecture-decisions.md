# Architecture Decision Records (ADRs)

## ADR-001: Serverless over Managed Infrastructure

**Status:** Accepted

**Context:** Precisamos escolher entre Glue (serverless) vs EMR (managed Spark cluster) para ETL.

**Decision:** AWS Glue (serverless)

**Rationale:**
- Zero management de clusters
- Pay-per-use (DPU-second billing)
- Para volumes do workshop (< 1M linhas), Glue é 10x mais barato que EMR
- Data Catalog integrado nativamente

**Trade-off:** Para volumes > 10TB/dia, EMR com spot instances pode ser mais econômico.

---

## ADR-002: Parquet over CSV para camadas Cleanse/Consume

**Status:** Accepted

**Context:** Formato de armazenamento para dados processados.

**Decision:** Apache Parquet

**Rationale:**
- Columnar: Athena lê apenas colunas necessárias → menor custo ($5/TB)
- Compressão: 5-10x menor que CSV
- Schema evolution suportado nativamente
- Predicate pushdown: filtros aplicados antes de ler dados
- Tipagem forte: evita problemas de inferência

---

## ADR-003: DynamoDB para lookups over S3/Glue Catalog

**Status:** Accepted

**Context:** Onde armazenar tabelas de referência (lookup) usadas durante transforms.

**Decision:** DynamoDB

**Rationale:**
- Latência < 10ms para point reads (Glue Job não espera)
- Pay-per-request elimina preocupação com capacity planning
- Ideal para key-value lookups simples
- PII tokenization precisa de leitura/escrita atômica

**Trade-off:** Para lookups > 400KB por item, considerar S3 + broadcast join.

---

## ADR-004: Step Functions over Airflow/MWAA

**Status:** Accepted

**Context:** Escolha de orquestrador para o pipeline ETL.

**Decision:** AWS Step Functions (Standard Workflows)

**Rationale:**
- Serverless, zero infra para gerenciar
- Visual debugging no Console
- Integração nativa com Glue (.sync para esperar conclusão)
- $0.025/1000 transições (vs ~$200-400/mês para MWAA)

**Trade-off:** Sem DAG dependency management cross-workflows. Para 50+ pipelines interdependentes, MWAA/Airflow seria melhor.

---

## ADR-005: Terraform Modules over Monolith

**Status:** Accepted

**Context:** Como organizar o código Terraform.

**Decision:** Módulos separados por domínio (s3, glue, dynamodb, step-functions)

**Rationale:**
- Cada módulo pode ser testado independentemente
- Reutilizável em outros projetos
- Facilita entendimento (cada módulo tem ~100 linhas)
- Environments (dev/prod) compõem módulos com variáveis diferentes
