# Jornada do Dado: Do Sistema Fonte ao Insight

## Rastreando um dado real pelo pipeline

Vamos seguir **uma única apólice** desde o sistema fonte até virar insight no dashboard.

---

## O Dado Original

No sistema Guidewire da seguradora, existe este registro:

```
Policy No: POL-2024-00345
Customer: Maria Santos (CPF: 123.456.789-09)
Product: Auto Premium
Effective: 01/15/2024
Expiration: 01/15/2025
Written Premium: R$ 15,000.00
State: SP
Status: Active
New/Renewal: Renewal
```

E no sistema de Claims:
```
Claim ID: CLM-88901
Policy: POL-2024-00345
Accident Date: 2024-04-22
Amount: R$ 8,500.00
Status: Paid
Type: Collision
```

---

## Etapa 1: Export e Upload (Collect)

O time de TI exporta os dados como CSV e coloca no S3:

**Arquivo:** `syntheticgeneral-policy-data.csv`
```csv
Policy No,Customer,CPF,Product,Effective,Expiration,Written Premium,State,Status,New/Renewal
POL-2024-00345,Maria Santos,123.456.789-09,Auto Premium,01/15/2024,01/15/2025,"R$ 15,000.00",SP,Active,Renewal
```

**Local:** `s3://collect-bucket/SyntheticGeneralData/PolicyData/syntheticgeneral-policy-data.csv`

**O que acontece:** S3 Event Notification → Lambda → Step Functions inicia

---

## Etapa 2: Schema Mapping (Collect → Cleanse)

**Arquivo de config:** `syntheticgeneraldata-policydata.csv`
```csv
SourceName,DestName
Policy No,policynumber
Customer,customername
CPF,cpf
Product,lineofbusiness
Effective,effectivedate
Expiration,expirationdate
Written Premium,writtenpremiumamount
State,state
Status,policystatus
New/Renewal,neworenewal
```

**Resultado:** Colunas renomeadas para nomes padronizados, sem espaços.

---

## Etapa 3: Transforms (Collect → Cleanse)

**Arquivo de config:** `syntheticgeneraldata-policydata.json`
```json
{
    "transform_spec": {
        "tokenize": ["cpf"],
        "currency": [{ "field": "writtenpremiumamount" }],
        "date": [
            { "field": "effectivedate", "format": "MM/dd/yyyy" },
            { "field": "expirationdate", "format": "MM/dd/yyyy" }
        ],
        "titlecase": ["customername"],
        "lookup": [
            { "field": "state", "lookup": "StateCd" }
        ]
    }
}
```

**O que acontece com cada campo:**

| Campo | Antes | Transform | Depois |
|---|---|---|---|
| cpf | `123.456.789-09` | `tokenize` | `a7f3b2c1...` (SHA256, original no DynamoDB) |
| writtenpremiumamount | `"R$ 15,000.00"` | `currency` | `15000.00` (decimal) |
| effectivedate | `01/15/2024` | `date` | `2024-01-15` (ISO date) |
| expirationdate | `01/15/2025` | `date` | `2025-01-15` (ISO date) |
| customername | `Maria Santos` | `titlecase` | `Maria Santos` (já estava ok) |
| state | `SP` | `lookup` | `São Paulo` (expandido via DynamoDB) |

---

## Etapa 4: Data Quality (Collect → Cleanse)

**Arquivo:** `dq-syntheticgeneraldata-policydata.json`
```json
{
    "after_transform": {
        "warn_rules": [
            "ColumnValues 'writtenpremiumamount' >= 0",
            "ColumnValues 'writtenpremiumamount' < 10000000"
        ],
        "halt_rules": [
            "(ColumnExists 'policynumber') and (IsComplete 'policynumber')",
            "(ColumnExists 'effectivedate') and (IsComplete 'effectivedate')"
        ]
    }
}
```

**Resultado para nosso dado:**
- ✅ writtenpremiumamount = 15000 (>= 0 e < 10M)
- ✅ policynumber existe e não é null
- ✅ effectivedate existe e não é null
- **Pipeline continua!**

---

## Etapa 5: Salvar no Cleanse (Parquet)

**Local:** `s3://cleanse-bucket/syntheticgeneraldata/policydata/year=2024/month=06/day=12/part-00000.parquet`

**Dado salvo (schema Apache Parquet):**
```
policynumber: STRING = "POL-2024-00345"
customername: STRING = "Maria Santos"
cpf: STRING = "a7f3b2c1d4e5f6..."  (tokenizado!)
lineofbusiness: STRING = "Auto Premium"
effectivedate: DATE = 2024-01-15
expirationdate: DATE = 2025-01-15
writtenpremiumamount: DECIMAL(10,2) = 15000.00
state: STRING = "São Paulo"
policystatus: STRING = "Active"
neworenewal: STRING = "Renewal"
execution_id: STRING = "run-20240612-143022"
year: INT = 2024
month: INT = 6
day: INT = 12
```

**Glue Data Catalog:** Tabela `syntheticgeneraldata.policydata` atualizada.

---

## Etapa 6: Spark SQL JOIN (Cleanse → Consume)

**Arquivo:** `spark-syntheticgeneraldata-policydata.sql`
```sql
SELECT
    p.policynumber,
    p.effectivedate,
    p.expirationdate,
    p.writtenpremiumamount,
    p.lineofbusiness,
    p.neworenewal,
    p.state,
    c.accidentyeartotalincurredamount,
    -- Cálculo de Loss Ratio
    CASE 
        WHEN p.writtenpremiumamount > 0 
        THEN c.accidentyeartotalincurredamount / p.writtenpremiumamount
        ELSE 0 
    END as loss_ratio,
    p.execution_id,
    p.year,
    p.month,
    p.day
FROM syntheticgeneraldata.policydata p
LEFT OUTER JOIN syntheticgeneraldata.claimdata c
    ON p.policynumber = c.policynumber
```

**Resultado para nossa apólice:**
```
policynumber: "POL-2024-00345"
effectivedate: 2024-01-15
expirationdate: 2025-01-15
writtenpremiumamount: 15000.00
lineofbusiness: "Auto Premium"
neworenewal: "Renewal"
state: "São Paulo"
accidentyeartotalincurredamount: 8500.00  ← veio do JOIN com Claims!
loss_ratio: 0.5667  ← 8500/15000 = 56.67%
```

---

## Etapa 7: Consumo (Query no Athena)

O analista abre o Athena e executa:

```sql
SELECT 
    lineofbusiness,
    COUNT(*) as num_policies,
    SUM(writtenpremiumamount) as total_gwp,
    AVG(loss_ratio) as avg_loss_ratio
FROM syntheticgeneraldata_consume.policydata
WHERE year = 2024
GROUP BY lineofbusiness
ORDER BY total_gwp DESC;
```

**Resultado:**
| lineofbusiness | num_policies | total_gwp | avg_loss_ratio |
|---|---|---|---|
| Auto Premium | 12,450 | 142,500,000 | 0.72 |
| Home Standard | 8,200 | 98,000,000 | 0.55 |
| Business All Risk | 3,100 | 186,000,000 | 0.81 |

---

## Etapa 8: Insight no Dashboard

O QuickSight mostra:

```
🔴 ALERTA: Business All Risk com Loss Ratio de 81%
   Acima do target de 75% pelo segundo mês consecutivo.
   
   Recomendação: Revisar pricing ou reduzir exposição neste segmento.
```

---

## Resumo da Jornada

```
"R$ 15,000.00"  ──▶  15000.00  ──▶  JOIN com claim  ──▶  LR 56.67%  ──▶  Dashboard

  String suja      Decimal limpo     Dado cruzado      Métrica          Decisão
  (Collect)        (Transform)       (Spark SQL)       (Cálculo)        (QuickSight)
```

**Tempo total:** Upload → Dashboard = ~5 minutos (Glue Job ~3min + Athena ~2sec)

**Antes do InsuranceLake:** Esse mesmo processo levava semanas e era propenso a erros.

---

## O que deu certo nesta jornada

1. ✅ CPF tokenizado (LGPD compliance)
2. ✅ Moeda convertida automaticamente (R$ string → decimal)
3. ✅ Data normalizada (MM/dd/yyyy → ISO)
4. ✅ JOIN automático com Claims
5. ✅ Loss Ratio calculado sem intervenção humana
6. ✅ Dado particionado por data (query eficiente)
7. ✅ Auditável (execution_id rastreia cada processamento)
8. ✅ Reproduzível (mesma config gera mesmo resultado)
