# Fluxo de Negócio: Como uma Seguradora Opera

## O Ciclo de Vida de um Seguro

```
┌────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   1. COTAÇÃO           2. EMISSÃO          3. VIGÊNCIA              │
│   ─────────           ──────────          ──────────              │
│   Cliente pede  ──▶  Aceita? Emite  ──▶  Apólice ativa           │
│   preço do seguro     a apólice            (cobrindo o risco)      │
│                                                                     │
│   4. SINISTRO          5. REGULAÇÃO        6. LIQUIDAÇÃO            │
│   ───────────         ───────────         ────────────            │
│   Evento acontece ──▶ Investiga se  ──▶  Paga o segurado          │
│   (batida, roubo)     tem cobertura       (ou nega com razão)      │
│                                                                     │
│   7. RENOVAÇÃO                                                      │
│   ───────────                                                      │
│   Apólice expira ──▶ Renova (com novo preço baseado no histórico)  │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

---

## O Fluxo de Dinheiro

```
     ENTRADA                                          SAÍDA
     ────────                                        ──────

     ┌──────────────┐                          ┌──────────────────┐
     │   Prêmios    │                          │  Sinistros Pagos │
     │  (premiums)  │                          │    (claims)      │
     │              │    ┌────────────────┐    │                  │
     │  R$ recebido │───▶│   SEGURADORA   │───▶│  R$ pago ao      │
     │  dos clientes│    │                │    │  segurado        │
     └──────────────┘    └────────────────┘    └──────────────────┘
                                │
                                │ sobra?
                                ▼
                    ┌─────────────────────────┐
                    │  Resultado Técnico       │
                    │  = Prêmio - Sinistros   │
                    │    - Despesas            │
                    │                         │
                    │  Se > 0 → LUCRO         │
                    │  Se < 0 → PREJUÍZO      │
                    └─────────────────────────┘
```

---

## Métricas Fundamentais

### 1. Written Premium (Prêmio Emitido)

```
Janeiro: Vendeu 100 apólices × R$ 12.000 = R$ 1.200.000 de Written Premium

É como o "faturamento bruto" da seguradora.
Mas CUIDADO: esse dinheiro não é todo da seguradora ainda!
```

### 2. Earned Premium (Prêmio Ganho)

```
Apólice anual de R$ 12.000 emitida em Janeiro:

Jan: ganhou R$ 1.000
Fev: ganhou R$ 1.000
Mar: ganhou R$ 1.000
...
Dez: ganhou R$ 1.000

Total ganho no ano: R$ 12.000

MAS se o cliente cancelar em Março:
Total ganho: R$ 3.000 (devolveu R$ 9.000)
```

**No InsuranceLake:** O transform `earnedpremium` faz esse cálculo automaticamente!

### 3. Incurred Claims (Sinistros Ocorridos)

```
Sinistro aberto: R$ 50.000 (estimativa inicial)
Regulação avalia: R$ 65.000 (estimativa revisada)
Pagamento final: R$ 62.000 (liquidação)

Incurred = Pagos + Reserva de sinistros pendentes
```

### 4. Loss Ratio

```
             Sinistros Incurred      R$ 7.000.000
Loss Ratio = ──────────────────── = ──────────────── = 70%
             Earned Premium          R$ 10.000.000
```

### 5. Combined Ratio

```
                 Sinistros + Despesas     R$ 7M + R$ 2.5M
Combined Ratio = ────────────────────── = ───────────────── = 95%
                 Earned Premium            R$ 10M

< 100% → Lucro operacional
> 100% → Prejuízo operacional
```

---

## Por que Cruzar Dados é Difícil?

### Problema 1: Dados em sistemas diferentes

```
Sistema de Apólices (Guidewire):
┌────────────┬──────────────┬─────────────┬────────────┐
│ PolicyNo   │ CustomerName │ Premium     │ StartDate  │
├────────────┼──────────────┼─────────────┼────────────┤
│ POL-001    │ João Silva   │ 12000.00    │ 01/15/2024 │
│ POL-002    │ Maria Santos │ 8500.00     │ 02/01/2024 │
└────────────┴──────────────┴─────────────┴────────────┘

Sistema de Sinistros (Duck Creek):
┌───────────────┬──────────────┬───────────┬────────────────┐
│ CLAIM_ID      │ POLICY_NUMBER│ AMOUNT    │ ACCIDENT_DATE  │
├───────────────┼──────────────┼───────────┼────────────────┤
│ CLM-10001     │ POL-001      │ 45000     │ 2024-03-22     │
│ CLM-10002     │ POL-001      │ 12000     │ 2024-06-15     │
└───────────────┴──────────────┴───────────┴────────────────┘
```

**Problemas:**
- Nomes de colunas diferentes: `PolicyNo` vs `POLICY_NUMBER`
- Formato de data diferente: `01/15/2024` vs `2024-03-22`
- Formato de valor diferente: `12000.00` vs `45000` (com ou sem decimal)
- Encoding diferente: UTF-8 vs Latin-1

### Problema 2: Granularidade diferente

- Apólice: 1 linha por contrato (anual)
- Sinistro: N linhas por apólice (cada evento)
- Financeiro: 1 linha por parcela de pagamento (mensal)

Para calcular Loss Ratio precisa **agregar** sinistros por apólice e **proporcionalizar** o prêmio pelo tempo.

### Problema 3: Dados sujos

```
Exemplos reais de problemas em dados de seguros:

- Prêmio = "R$ 12.000,00" (string com moeda e separador brasileiro)
- Data = "00/00/0000" (data inválida)
- CPF = "123.456.789-09" (precisa tokenizar por LGPD)
- LOB = "auto", "AUTO", "Automóvel", "Veículos" (mesmo conceito, 4 formas)
- Linha extra no CSV: "TOTAL,,52500" (totalizador que quebra análise)
- Campo vazio que deveria ser obrigatório
```

---

## O que o InsuranceLake Faz com Cada Problema

| Problema | Solução InsuranceLake | Onde |
|---|---|---|
| Nomes diferentes | Schema Mapping (CSV) | Collect→Cleanse |
| Formatos de data | Transform `date` | Collect→Cleanse |
| Moeda formatada | Transform `currency` | Collect→Cleanse |
| Valores padronizados | Transform `lookup` (DynamoDB) | Collect→Cleanse |
| PII exposta | Transform `tokenize` / `hash` | Collect→Cleanse |
| Dados corrompidos | Data Quality `quarantine_rules` | Collect→Cleanse |
| Campos obrigatórios | Data Quality `halt_rules` | Collect→Cleanse |
| Cruzamento de tabelas | Spark SQL (JOIN) | Cleanse→Consume |
| Cálculo earned premium | Transform `earnedpremium` | Collect→Cleanse |
| Expansão mensal | Transform `expandpolicymonths` | Collect→Cleanse |
| Visualização | QuickSight + Athena | Consume |

---

## Resultado Final: O que o Negócio Ganha

### Dashboard do CFO (exemplo)

```
┌──────────────────────────────────────────────────────────┐
│  INSURANCE LAKE - Executive Dashboard       Jun/2024     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  GWP (Gross Written Premium)     │  Loss Ratio           │
│  R$ 45.2M (+12% YoY)            │  68.5% (target: 70%)  │
│  ██████████████░░░               │  ████████████░░░░░    │
│                                                          │
│  ────────────────────────────────────────────────────    │
│                                                          │
│  Loss Ratio por LOB:                                     │
│  ┌──────────┬───────────┬───────────┐                   │
│  │ Auto     │ ████ 72%  │ ⚠️ Atenção │                   │
│  │ Home     │ ███ 55%   │ ✅ Bom     │                   │
│  │ Business │ █████ 81% │ 🔴 Crítico │                   │
│  │ Health   │ ████ 69%  │ ✅ Bom     │                   │
│  └──────────┴───────────┴───────────┘                   │
│                                                          │
│  Insight: LOB "Business" ultrapassou 80%. Investigar     │
│  sinistros grandes em Q2.                                │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Ação de Negócio Resultante

Com esse dashboard, o CFO decide:
1. **Business Insurance** com 81% loss ratio → aumentar preço na renovação
2. **Home Insurance** com 55% → talvez reduzir preço para crescer market share
3. **Auto Insurance** com 72% → investigar se há fraude em região específica

**Sem o Data Lake:** Essa decisão levaria semanas. 
**Com o Data Lake:** Decisão em minutos, com dados confiáveis.

---

## Resumo para Apresentação (1 slide)

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  PROBLEMA:  Seguradora com dados em 5+ sistemas diferentes   │
│             não consegue calcular Loss Ratio rapidamente      │
│                                                              │
│  SOLUÇÃO:   Data Lake automatizado na AWS (InsuranceLake)    │
│             que coleta, limpa, cruza e disponibiliza dados    │
│                                                              │
│  RESULTADO: De 3 semanas para minutos                        │
│             Single source of truth                            │
│             Decisões data-driven                             │
│             Compliance regulatória automatizada              │
│                                                              │
│  TECNOLOGIA: S3 + Glue + Step Functions + Lambda +           │
│              DynamoDB + Athena + CDK (serverless, <$2/run)   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```
