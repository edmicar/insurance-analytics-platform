# Mapa Mental: InsuranceLake — Visão Completa

## 🧠 Mapa Mental Principal

```
                            ┌─────────────────────────────────┐
                            │      INSURANCELAKE              │
                            │   "Data Lake para Seguros"      │
                            └───────────────┬─────────────────┘
                                            │
              ┌─────────────────────────────┼─────────────────────────────┐
              │                             │                             │
              ▼                             ▼                             ▼
     ┌────────────────┐          ┌────────────────┐           ┌────────────────┐
     │  POR QUÊ?      │          │  O QUÊ?        │           │  PARA QUEM?    │
     │  (Problema)     │          │  (Solução)     │           │  (Stakeholders)│
     └───────┬────────┘          └───────┬────────┘           └───────┬────────┘
             │                           │                            │
     ┌───────┼───────┐          ┌────────┼────────┐         ┌────────┼────────┐
     │       │       │          │        │        │         │        │        │
     ▼       ▼       ▼          ▼        ▼        ▼         ▼        ▼        ▼
   Dados   Lento   Erros     Collect Cleanse Consume     CFO    Atuário  Regulador
  Silos   (semanas) Manual    (S3)   (Glue)   (Athena)
```

---

## 🔍 Nível 1: O PROBLEMA

```
                         ┌──────────────────────┐
                         │   PROBLEMA CENTRAL   │
                         │                      │
                         │ "Não consigo saber   │
                         │  se estou ganhando   │
                         │  ou perdendo dinheiro │
                         │  por produto"        │
                         └──────────┬───────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            │                       │                       │
            ▼                       ▼                       ▼
   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
   │ DADOS EM SILOS  │   │ PROCESSO LENTO  │   │ RISCO DE ERROS  │
   └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
            │                      │                      │
     ┌──────┼──────┐       ┌──────┼──────┐       ┌──────┼──────┐
     │      │      │       │      │      │       │      │      │
     ▼      ▼      ▼       ▼      ▼      ▼       ▼      ▼      ▼
  Policy  Claims Finance  Export  Excel  Manual  Formato Cálculo Duplica
  System  System  System  CSV    Merge  Report  errado  errado  ção
  (Guide  (Duck   (SAP)  (dias) (trava) (semanas)
   wire)   Creek)
```

---

## 🔍 Nível 2: A SOLUÇÃO (Pipeline)

```
                    ┌──────────────────────────────────────┐
                    │         PIPELINE INSURANCELAKE        │
                    └──────────────────┬───────────────────┘
                                       │
         ┌─────────────────────────────┼─────────────────────────────┐
         │                             │                             │
         ▼                             ▼                             ▼
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│    COLLECT      │         │    CLEANSE      │         │    CONSUME      │
│   (Coletar)     │         │   (Limpar)      │         │   (Consumir)    │
│                 │         │                 │         │                 │
│  "Aceita tudo   │         │  "Padroniza e   │         │  "Pronto para   │
│   como veio"    │         │   valida"       │         │   decisão"      │
└────────┬────────┘         └────────┬────────┘         └────────┬────────┘
         │                           │                           │
    ┌────┼────┐              ┌───────┼───────┐            ┌──────┼──────┐
    │    │    │              │       │       │            │      │      │
    ▼    ▼    ▼              ▼       ▼       ▼            ▼      ▼      ▼
  CSV  JSON Excel      Schema   Transform  Data       Spark  Athena  Quick
                       Mapping  (PySpark)  Quality    SQL    Views   Sight
                                                     (JOIN)
```

---

## 🔍 Nível 3: DADOS DO SEGURO

```
                        ┌────────────────────┐
                        │  DADOS DE SEGURO   │
                        └─────────┬──────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
          ▼                       ▼                       ▼
 ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
 │    APÓLICE      │    │    SINISTRO     │    │   FINANCEIRO    │
 │   (Policy)      │    │    (Claim)      │    │   (Billing)     │
 └────────┬────────┘    └────────┬────────┘    └────────┬────────┘
          │                      │                      │
   ┌──────┼──────┐       ┌──────┼──────┐       ┌──────┼──────┐
   │      │      │       │      │      │       │      │      │
   ▼      ▼      ▼       ▼      ▼      ▼       ▼      ▼      ▼
 Quem?  Quanto? Quando? O que?  Quanto  Status  Parcela Comis  Imposto
 (Segu  (Prê-  (Vigên  aconte  custou? (pago/  (mensal) são
  rado)  mio)   cia)    ceu?    (valor) aberto)
```

---

## 🔍 Nível 4: MÉTRICAS DE NEGÓCIO

```
                    ┌──────────────────────────────┐
                    │   MÉTRICAS DO SEGURO         │
                    │   (O que queremos calcular)  │
                    └──────────────┬───────────────┘
                                   │
       ┌───────────────────────────┼───────────────────────────┐
       │                           │                           │
       ▼                           ▼                           ▼
┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│  RECEITA     │          │  DESPESA     │          │  RESULTADO   │
└──────┬───────┘          └──────┬───────┘          └──────┬───────┘
       │                         │                         │
  ┌────┼────┐              ┌─────┼─────┐             ┌─────┼─────┐
  │    │    │              │     │     │             │     │     │
  ▼    ▼    ▼              ▼     ▼     ▼             ▼     ▼     ▼
GWP   EP   Earned      Claims Reserva Despesa    Loss  Combined Lucro/
(emi  (ga  Premium     Pagos  (IBNR)  Admin     Ratio  Ratio   Prejuí
 ti-  nho  Mensal                                              zo
 do)  ção)

FÓRMULA-CHAVE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Loss Ratio = Sinistros Incurred / Earned Premium
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔍 Nível 5: TECNOLOGIA (Serviços AWS)

```
                       ┌─────────────────────────┐
                       │   STACK TECNOLÓGICO     │
                       └────────────┬────────────┘
                                    │
     ┌──────────────────────────────┼──────────────────────────────┐
     │                              │                              │
     ▼                              ▼                              ▼
┌──────────┐                 ┌──────────┐                 ┌──────────┐
│ARMAZENAR │                 │PROCESSAR │                 │ CONSUMIR │
└────┬─────┘                 └────┬─────┘                 └────┬─────┘
     │                            │                            │
  ┌──┼──┐                   ┌─────┼─────┐               ┌─────┼─────┐
  │     │                   │     │     │               │     │     │
  ▼     ▼                   ▼     ▼     ▼               ▼     ▼     ▼
 S3   DynamoDB           Glue   Step   Lambda         Athena Quick  Amazon
(dados)(lookup/           (Py   Func-  (trigger       (SQL)  Sight   Q
       audit)            Spark) tions   + audit)             (BI)  (GenAI)
                                │
                         ┌──────┼──────┐
                         │             │
                         ▼             ▼
                    Collect→       Cleanse→
                    Cleanse        Consume
                    (transform)    (SQL JOIN)
```

---

## 🔍 Nível 6: QUEM USA E PARA QUÊ

```
                        ┌────────────────────┐
                        │   STAKEHOLDERS     │
                        └─────────┬──────────┘
                                  │
    ┌─────────────────────────────┼─────────────────────────────┐
    │              │              │              │               │
    ▼              ▼              ▼              ▼               ▼
┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐      ┌────────┐
│  CFO   │   │Atuário │   │Under-  │   │Regula- │      │  TI /  │
│        │   │        │   │writer  │   │dor     │      │Data Eng│
└───┬────┘   └───┬────┘   └───┬────┘   └───┬────┘      └───┬────┘
    │            │            │            │               │
    ▼            ▼            ▼            ▼               ▼
"Estou       "Qual a      "Devo        "Cadê o        "Pipeline
 lucrando?"  reserva      renovar      relatório      rodou sem
             necessária?" esta         trimestral?"   erro?"
                          apólice?"
    │            │            │            │               │
    ▼            ▼            ▼            ▼               ▼
Dashboard    Triângulo    Score de     Report         CloudWatch
Loss Ratio   de Desenvol  Risco por    Automático     + Alertas
por LOB      vimento      Cliente      (SUSEP/IFRS)
```

---

## 🔍 Nível 7: FLUXO TEMPORAL (Linha do Tempo)

```
TEMPO ──────────────────────────────────────────────────────────────────────▶

│ T=0            │ T=1min         │ T=3min           │ T=5min         │
│ Upload arquivo │ Lambda dispara │ Glue Job executa │ Dados prontos  │
│                │ Step Functions │ Transforms+DQ    │ no Athena      │
│                │                │                  │                │
▼                ▼                ▼                  ▼                
┌──────┐    ┌──────┐        ┌──────┐          ┌──────┐
│  S3  │───▶│Lambda│───────▶│ Glue │─────────▶│Athena│
│Collect│    │Trigger│       │PySpark│         │Query │
└──────┘    └──────┘        └──────┘          └──────┘
                                                  │
                                                  ▼
                                            ┌──────────┐
                                            │QuickSight│
                                            │Dashboard │
                                            └──────────┘
                                                  │
                                                  ▼
                                            ┌──────────┐
                                            │ DECISÃO  │
                                            │ de negócio│
                                            └──────────┘

ANTES DO INSURANCELAKE:
│ Semana 1       │ Semana 2       │ Semana 3       │
│ Export CSVs    │ Merge no Excel │ Relatório pronto│
│ (pedir para TI)│ (manual, erros)│ (talvez errado)│
```

---

## 🔍 MAPA MENTAL DE DECISÕES ARQUITETURAIS

```
                     ┌─────────────────────────────┐
                     │  POR QUE ESSA ARQUITETURA?  │
                     └─────────────┬───────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         │                         │                         │
         ▼                         ▼                         ▼
  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
  │  SERVERLESS  │         │    3 CAMADAS │         │     IaC      │
  │  (sem server)│         │   (S3 buckets)│        │   (CDK)      │
  └──────┬───────┘         └──────┬───────┘         └──────┬───────┘
         │                        │                        │
    ┌────┼────┐             ┌─────┼─────┐            ┌─────┼─────┐
    │         │             │           │            │           │
    ▼         ▼             ▼           ▼            ▼           ▼
 Escala     Custo       Auditoria  Reprocessa    Reproduzí  Multi-env
 automá-    zero        (raw       mento fácil   vel        (dev/test/
 tica       quando      intacto)   (só muda      (mesmo     prod)
            parado                  config)       resultado
                                                  sempre)
```

---

## 📋 CHECKLIST: Entendi o Problema de Negócio?

Use este checklist para validar seu entendimento:

```
□ Consigo explicar o que é uma apólice em 1 frase
□ Consigo explicar o que é um sinistro em 1 frase
□ Sei a diferença entre Written Premium e Earned Premium
□ Sei calcular Loss Ratio de cabeça
□ Entendo por que dados em silos é um problema
□ Consigo explicar as 3 camadas (Collect, Cleanse, Consume)
□ Sei quais serviços AWS fazem cada parte
□ Entendo o trigger automático (S3 → Lambda → Step Functions)
□ Sei por que Parquet é melhor que CSV para analytics
□ Consigo explicar para um não-técnico o que o pipeline faz
□ Entendo o valor de negócio (de semanas para minutos)
□ Sei quem são os stakeholders e o que cada um precisa
```
