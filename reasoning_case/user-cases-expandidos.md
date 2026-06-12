# User Cases Expandidos: Da Base do Workshop ao Mundo Real

## Mapa de Evolução

```
                         WORKSHOP BASE
                    ┌─────────────────────┐
                    │  Policy + Claims    │
                    │  ETL → Dashboard    │
                    └──────────┬──────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
    ┌───────────┐      ┌───────────┐      ┌───────────┐
    │  FASE 1   │      │  FASE 2   │      │  FASE 3   │
    │ Expandir  │      │ Inteligên │      │ Plataforma│
    │ Dados     │      │ cia       │      │ Completa  │
    └─────┬─────┘      └─────┬─────┘      └─────┬─────┘
          │                   │                   │
    ┌─────┼─────┐      ┌─────┼─────┐      ┌─────┼─────┐
    │     │     │      │     │     │      │     │     │
    ▼     ▼     ▼      ▼     ▼     ▼      ▼     ▼     ▼
  UC1   UC2   UC3    UC4   UC5   UC6    UC7   UC8   UC9
```

---

## FASE 1: Expandir a Base de Dados

### UC1 — Múltiplas Linhas de Negócio (Multi-LOB)

**Problema:** Workshop usa apenas "SyntheticGeneralData". Seguradoras reais têm 5-15 LOBs diferentes.

**O que fazer:**
```
collect/
├── AutoInsurance/
│   ├── PolicyData/
│   ├── ClaimData/
│   └── VehicleData/        ← NOVO: dados do veículo
├── HomeInsurance/
│   ├── PolicyData/
│   ├── ClaimData/
│   └── PropertyData/       ← NOVO: dados do imóvel
├── LifeInsurance/
│   ├── PolicyData/
│   ├── ClaimData/          (aqui = morte/invalidez)
│   └── BeneficiaryData/    ← NOVO: beneficiários
└── HealthInsurance/
    ├── PolicyData/
    ├── ClaimData/           (aqui = consultas/exames)
    └── ProviderData/        ← NOVO: rede credenciada
```

**Desafio técnico:**
- Cada LOB tem schema diferente
- Precisa de configs separadas (mapping, transforms, DQ) por LOB
- Mas métricas consolidadas (Loss Ratio total da companhia)

**Spark SQL para consolidação:**
```sql
-- View consolidada multi-LOB
SELECT 'Auto' as lob, policynumber, writtenpremiumamount, loss_ratio
FROM autoinsurance_consume.policydata
UNION ALL
SELECT 'Home' as lob, policynumber, writtenpremiumamount, loss_ratio
FROM homeinsurance_consume.policydata
UNION ALL
SELECT 'Life' as lob, policynumber, writtenpremiumamount, loss_ratio
FROM lifeinsurance_consume.policydata
```

**Habilidades desenvolvidas:** Multi-pipeline management, UNION, padronização cross-LOB

---

### UC2 — Dados de Terceiros (Enriquecimento)

**Problema:** Dados internos sozinhos não contam a história completa. Precisa de dados externos.

**O que fazer:**
```
collect/
├── ExternalData/
│   ├── WeatherData/        ← Clima (correlação com sinistros auto/home)
│   ├── CensusData/         ← Dados demográficos por CEP
│   ├── VehicleRegistry/    ← Tabela FIPE / valor do veículo
│   └── CatastropheData/    ← Eventos catastróficos (enchente, granizo)
```

**Exemplo de enriquecimento:**
```sql
-- JOIN com dados de catástrofe para identificar sinistros correlacionados
SELECT
    c.policynumber,
    c.accidentdate,
    c.amount,
    cat.event_type,
    cat.event_severity,
    CASE WHEN cat.event_id IS NOT NULL THEN 'CAT' ELSE 'Normal' END as claim_category
FROM autoinsurance.claimdata c
LEFT JOIN externaldata.catastrophedata cat
    ON c.state = cat.state
    AND c.accidentdate BETWEEN cat.start_date AND cat.end_date
```

**Valor de negócio:** Separar sinistros normais de catastróficos para precificação mais precisa.

**Habilidades desenvolvidas:** Data enrichment, external data integration, JOIN complexos

---

### UC3 — Histórico e Série Temporal

**Problema:** Workshop carrega apenas uma partição de dados. Produção tem anos de histórico.

**O que fazer:**
- Carregar 3-5 anos de dados históricos com partition override
- Implementar processamento incremental (apenas delta)
- Criar views com window functions para tendências

**Implementação de carga histórica:**
```bash
# Upload com override de partição por ano/mês
for year in 2020 2021 2022 2023 2024; do
  for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
    aws s3 cp data/policy-${year}-${month}.csv \
      s3://collect-bucket/AutoInsurance/PolicyData/${year}/${month}/01/
  done
done
```

**Spark SQL para tendência:**
```sql
SELECT
    year,
    month,
    SUM(writtenpremiumamount) as monthly_gwp,
    SUM(accidentyeartotalincurredamount) / SUM(earnedpremium) as monthly_lr,
    -- Média móvel 12 meses
    AVG(SUM(writtenpremiumamount)) OVER (
        ORDER BY year, month 
        ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) as rolling_12m_gwp
FROM autoinsurance_consume.policydata
GROUP BY year, month
ORDER BY year, month
```

**Habilidades desenvolvidas:** Time-series, window functions, partitioning strategy, incremental loads

---

## FASE 2: Adicionar Inteligência

### UC4 — Scoring de Risco (Underwriting)

**Problema:** Underwriters avaliam risco manualmente. Precisam de um score automatizado.

**Arquitetura:**
```
Consume Data → Feature Engineering → ML Model → Score → Dashboard
```

**Features para o modelo:**
```sql
SELECT
    p.policynumber,
    p.lineofbusiness,
    p.state,
    p.writtenpremiumamount,
    -- Features calculadas
    COUNT(c.claimid) as historical_claim_count,
    COALESCE(SUM(c.amount), 0) as historical_claim_total,
    COALESCE(AVG(c.amount), 0) as avg_claim_amount,
    DATEDIFF(CURRENT_DATE, MIN(p.effectivedate)) as customer_tenure_days,
    p.neworenewal,
    -- Target
    CASE 
        WHEN SUM(c.amount) / NULLIF(p.writtenpremiumamount, 0) > 0.8 
        THEN 1 ELSE 0 
    END as high_risk_flag
FROM autoinsurance_consume.policydata p
LEFT JOIN autoinsurance_consume.claimdata c ON p.policynumber = c.policynumber
GROUP BY p.policynumber, p.lineofbusiness, p.state, 
         p.writtenpremiumamount, p.neworenewal
```

**Modelo:** XGBoost no SageMaker
**Output:** Score de 0-100 para cada apólice na renovação

**Valor de negócio:** 
- Score alto → aumentar preço ou recusar renovação
- Score baixo → oferecer desconto para reter cliente bom

**Habilidades desenvolvidas:** Feature engineering, ML integration, SageMaker

---

### UC5 — Detecção de Fraude

**Problema:** ~10% dos sinistros de auto têm indicadores de fraude. Detecção manual é cara e lenta.

**Red flags automatizáveis:**
```sql
SELECT
    c.claimid,
    c.policynumber,
    c.amount,
    c.accidentdate,
    p.effectivedate,
    -- Indicadores de fraude
    CASE WHEN DATEDIFF(c.accidentdate, p.effectivedate) < 30 
         THEN 1 ELSE 0 END as flag_new_policy_claim,
    CASE WHEN c.amount > p.writtenpremiumamount * 3 
         THEN 1 ELSE 0 END as flag_high_severity,
    CASE WHEN claim_count_12m > 3 
         THEN 1 ELSE 0 END as flag_frequent_claimer,
    CASE WHEN c.accidentdate = '2024-01-01' OR c.accidentdate = '2024-12-31'
         THEN 1 ELSE 0 END as flag_holiday_claim,
    -- Score composto
    (flag_new_policy + flag_high_severity + flag_frequent + flag_holiday) as fraud_score
FROM claims c
JOIN policies p ON c.policynumber = p.policynumber
```

**Pipeline adicional:**
1. Score calculado automaticamente no Consume
2. Scores > 3 → alerta para equipe de investigação
3. Dashboard com mapa de calor geográfico de fraude
4. ML model (Bedrock/SageMaker) para análise de texto de descrição do sinistro

**Habilidades desenvolvidas:** Anomaly detection, rules engine, event-driven alerts

---

### UC6 — Precificação Dinâmica (Pricing)

**Problema:** Preço do seguro é calculado anualmente com planilhas. Mercado exige agilidade.

**O que construir:**
```
                 ┌─────────────────────────────────────┐
                 │        PRICING ENGINE               │
                 ├─────────────────────────────────────┤
                 │                                     │
                 │  Inputs:                            │
                 │  ├── Loss Ratio histórico (3 anos)  │
                 │  ├── Frequência de sinistros        │
                 │  ├── Severidade média              │
                 │  ├── Inflação (IPCA)               │
                 │  ├── Dados de mercado (concorrência)│
                 │  └── Custo de aquisição            │
                 │                                     │
                 │  Output:                            │
                 │  └── Preço sugerido por perfil      │
                 │                                     │
                 └─────────────────────────────────────┘
```

**Cálculo básico de pricing:**
```sql
-- Burning Cost (custo histórico puro)
SELECT
    lineofbusiness,
    state,
    vehicle_type,
    -- Taxa pura
    SUM(incurred_claims) / SUM(earned_premium) as pure_loss_ratio,
    -- Frequência × Severidade
    COUNT(claims) / COUNT(DISTINCT policies) as frequency,
    AVG(claim_amount) as severity,
    frequency * severity as burning_cost,
    -- Preço sugerido (com margem)
    burning_cost / (1 - 0.30) as suggested_premium  -- 30% de margem
FROM insurance_consume.policy_claims_view
WHERE year >= YEAR(CURRENT_DATE) - 3
GROUP BY lineofbusiness, state, vehicle_type
```

**Habilidades desenvolvidas:** Actuarial analytics, pricing models, simulation

---

## FASE 3: Plataforma Completa

### UC7 — Real-Time Claims Processing

**Problema:** Atualmente batch (uma vez por dia). Executivos querem visão em tempo real.

**Arquitetura híbrida:**
```
                REAL-TIME PATH (segundos)
         ┌─────────────────────────────────────────┐
         │                                         │
Claims ──┼──▶ API Gateway ──▶ Kinesis ──▶ Lambda ──┼──▶ Dashboard RT
System   │                                         │    (real-time)
         │         BATCH PATH (minutos)            │
         │                                         │
         └──▶ S3 Collect ──▶ Glue ──▶ Consume ────┘──▶ Dashboard Full
                                                        (histórico)
```

**Componentes:**
1. **API Gateway:** Endpoint REST para sistemas de claims
2. **Kinesis Data Stream:** Buffer de eventos
3. **Lambda (processor):** Enriquece evento + grava DynamoDB (dashboard RT)
4. **Kinesis Firehose:** Entrega micro-batch no S3 Collect (5 min)
5. **Pipeline existente:** Processa batch normalmente para histórico

**Valor:** CFO vê sinistros sendo abertos em tempo real. Pode reagir no mesmo dia.

**Habilidades desenvolvidas:** Event-driven architecture, streaming, hybrid batch+RT

---

### UC8 — Data Mesh / Multi-Tenant

**Problema:** Grupo segurador com 5 empresas (subsidiárias). Cada uma quer autonomia mas precisa de consolidação.

**Arquitetura Data Mesh:**
```
         ┌─────────────────────────────────────────────────────┐
         │              PLATAFORMA CENTRAL                      │
         │   (Governança, Catálogo, Segurança, Infra)          │
         └──────────────────────┬──────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│ SEGURADORA A │       │ SEGURADORA B │       │ SEGURADORA C │
│ (Auto)       │       │ (Vida)       │       │ (Saúde)      │
│              │       │              │       │              │
│ Seus dados   │       │ Seus dados   │       │ Seus dados   │
│ Suas configs │       │ Suas configs │       │ Suas configs │
│ Seus dashbds │       │ Seus dashbds │       │ Seus dashbds │
└──────┬───────┘       └──────┬───────┘       └──────┬───────┘
       │                      │                      │
       └──────────────────────┼──────────────────────┘
                              │
                              ▼
                    ┌────────────────────┐
                    │ CONSOLIDADO GRUPO  │
                    │ (Lake Formation    │
                    │  + DataZone)       │
                    └────────────────────┘
```

**Implementação:**
- **AWS Organizations:** Uma conta por subsidiária
- **Lake Formation:** Row-level security por tenant
- **DataZone:** Catálogo de dados cross-company (self-service discovery)
- **RAM (Resource Access Manager):** Compartilhar Glue Catalog entre contas

**Habilidades desenvolvidas:** Multi-account, data governance, Lake Formation, DataZone

---

### UC9 — GenAI para Documentos e Atendimento

**Problema:** 60% do trabalho de claims processing é ler documentos (boletim de ocorrência, fotos, laudos).

**Pipeline de documentos:**
```
PDF/Imagem → Textract (OCR) → Bedrock Claude (extração) → JSON → InsuranceLake
```

**Chatbot de atendimento:**
```
Cliente pergunta: "Qual o status do meu sinistro CLM-88901?"
     │
     ▼
Bedrock Agent → Consulta Athena → Responde: 
"Seu sinistro está em análise. Valor estimado: R$ 8.500. 
 Previsão de pagamento: 15 dias úteis."
```

**Implementação:**
1. **Amazon Textract:** OCR de documentos de sinistro
2. **Amazon Bedrock (Claude):** Extrai campos estruturados do texto
3. **Knowledge Base (Bedrock):** RAG sobre políticas da empresa
4. **Agent (Bedrock):** Atende perguntas do cliente via chat

**Habilidades desenvolvidas:** GenAI, RAG, Agents, document processing

---

## ROADMAP COMPLETO DE EVOLUÇÃO

```
TIMELINE ──────────────────────────────────────────────────────────────────▶

MÊS 1-2          MÊS 3-4          MÊS 5-6          MÊS 7-8          MÊS 9-12
─────────         ─────────         ─────────         ─────────         ─────────
Workshop          FASE 1            FASE 2            FASE 2+           FASE 3
Base              Expandir          Inteligência      ML Avançado       Plataforma
│                 │                 │                 │                 │
├── Deploy        ├── UC1:Multi-LOB ├── UC4:Score    ├── UC5:Fraude    ├── UC7:Real-time
├── ETL básico    ├── UC2:Enrich    ├── UC6:Pricing  │                 ├── UC8:Data Mesh
├── Transform     ├── UC3:Histórico │                │                 ├── UC9:GenAI
├── QuickSight    │                 │                │                 │
│                 │                 │                │                 │
▼                 ▼                 ▼                ▼                 ▼
NÍVEL:            NÍVEL:            NÍVEL:           NÍVEL:            NÍVEL:
Pleno             Pleno+            Sênior-          Sênior            Sênior+/
                                                                      Staff
```

---

## MATRIZ: Habilidade × User Case

| Habilidade | UC1 | UC2 | UC3 | UC4 | UC5 | UC6 | UC7 | UC8 | UC9 |
|---|---|---|---|---|---|---|---|---|---|
| PySpark/Glue | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | | |
| SQL Avançado | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | |
| CDK/IaC | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Machine Learning | | | | ✅ | ✅ | ✅ | | | |
| Streaming | | | | | | | ✅ | | |
| Multi-Account | | | | | | | | ✅ | |
| Governança (LF) | | | | | | | | ✅ | |
| GenAI/Bedrock | | | | | | | | | ✅ |
| Event-Driven | | ✅ | | | ✅ | | ✅ | | ✅ |
| Negócio Seguros | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## COMO APRESENTAR CADA UC EM ENTREVISTA/PORTFÓLIO

### Template de 5 Minutos

```
1. CONTEXTO (30s)
   "Uma seguradora com R$ 500M em prêmios anuais..."

2. PROBLEMA (30s)
   "Não conseguia calcular loss ratio em menos de 3 semanas..."

3. SOLUÇÃO (2min)
   "Implementei um data lake na AWS com..."
   [Diagrama de arquitetura]

4. RESULTADO (1min)
   "Reduziu de 3 semanas para 5 minutos"
   "Custo: < $2/execução"
   "Zero erros de cálculo"

5. APRENDIZADO (1min)
   "A decisão mais difícil foi X porque..."
   "Se fizesse de novo, mudaria Y..."
```

---

## PARTES FUTURAS (O que vem depois de tudo isso)

### Horizonte 1: Data Lakehouse (6-12 meses)
- Migrar de S3+Glue para **Apache Iceberg** tables
- Suporte a ACID transactions
- Time travel (query dados como estavam há 30 dias)
- Compaction e optimization automática

### Horizonte 2: Data Products (12-18 meses)
- Cada UC vira um "Data Product" no **Amazon DataZone**
- Self-service: analistas acessam sem depender de engenharia
- SLAs definidos (freshness, quality score)
- Contratos de dados entre producers e consumers

### Horizonte 3: AI-Native Insurance (18-24 meses)
- **Agentic AI:** Agentes autônomos que processam claims end-to-end
- **Automated Underwriting:** Cotação em segundos via modelo
- **Predictive Analytics:** Prever sinistros antes de acontecerem
- **Personalized Insurance:** Preço individualizado em tempo real (IoT + telematics)

```
EVOLUÇÃO DA MATURIDADE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Excel         Data Lake       Lakehouse       Data Products      AI-Native
   (manual)      (batch ETL)     (ACID+history)  (self-service)     (autônomo)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   VOCÊ ESTÁ          AQUI ──▶   PRÓXIMO PASSO
   AQUI (antes)       (workshop)
```
