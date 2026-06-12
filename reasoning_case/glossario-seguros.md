# Glossário: Termos do Setor de Seguros

## Termos do Negócio

| Termo | Em Português | Explicação Simples |
|---|---|---|
| **Policy** | Apólice | O contrato do seguro (quem, o quê, quanto, quando) |
| **Claim** | Sinistro | O evento que aciona o seguro (batida, roubo, incêndio) |
| **Premium** | Prêmio | O preço que o cliente paga pelo seguro |
| **Written Premium (GWP)** | Prêmio Emitido | Total vendido (registrado na emissão) |
| **Earned Premium** | Prêmio Ganho | Parcela do prêmio já "merecida" pelo tempo decorrido |
| **Unearned Premium** | Prêmio Não Ganho | Parcela do prêmio referente ao período futuro |
| **Incurred Claims** | Sinistros Ocorridos | Total de sinistros (pagos + reservados) |
| **Loss Ratio** | Índice de Sinistralidade | Sinistros ÷ Prêmio Ganho (quanto da receita vira sinistro) |
| **Combined Ratio** | Índice Combinado | (Sinistros + Despesas) ÷ Prêmio Ganho |
| **Underwriting** | Subscrição | Processo de avaliar e aceitar/rejeitar riscos |
| **Renewal** | Renovação | Quando o cliente renova a apólice no vencimento |
| **New Business** | Negócio Novo | Apólice vendida para cliente novo |
| **LOB (Line of Business)** | Ramo/Linha de Negócio | Tipo de seguro (auto, vida, residencial) |
| **Coverage** | Cobertura | O que está protegido (colisão, roubo, incêndio) |
| **Deductible** | Franquia | Valor que o segurado paga antes do seguro cobrir |
| **Endorsement** | Endosso | Alteração na apólice durante a vigência |
| **Reinsurance** | Resseguro | Seguro do seguro (seguradora transfere parte do risco) |
| **Cession** | Cessão | Parte do risco transferida ao ressegurador |
| **Retention** | Retenção | Parte do risco que a seguradora mantém |
| **Reserve** | Reserva | Estimativa de quanto será pago em sinistros futuros |
| **IBNR** | Sinistros Ocorridos mas Não Avisados | Reserva para sinistros que já aconteceram mas ainda não foram reportados |
| **Policyholder** | Segurado | A pessoa ou empresa que comprou o seguro |
| **Beneficiary** | Beneficiário | Quem recebe o pagamento do sinistro |
| **Effective Date** | Data de Início de Vigência | Quando a cobertura começa |
| **Expiration Date** | Data de Fim de Vigência | Quando a cobertura termina |
| **Accident Year** | Ano do Acidente | Ano em que o sinistro ocorreu (para análise atuarial) |
| **Policy Year** | Ano da Apólice | Período de 12 meses da apólice |

---

## Termos Técnicos (Data Engineering)

| Termo | Explicação |
|---|---|
| **ETL** | Extract, Transform, Load — processo de extrair, transformar e carregar dados |
| **Data Lake** | Repositório centralizado para dados em qualquer formato |
| **Schema Mapping** | Renomear e padronizar nomes de colunas |
| **PII** | Personally Identifiable Information — dados pessoais (CPF, nome, email) |
| **Tokenization** | Substituir dado sensível por token (reversível ou não) |
| **Partitioning** | Dividir dados em pastas por critério (ano/mês/dia) para performance |
| **Parquet** | Formato colunar comprimido, eficiente para analytics |
| **Data Catalog** | Metastore que descreve quais tabelas/colunas existem |
| **Data Quality** | Regras automatizadas para validar dados (completude, formato, range) |
| **Data Lineage** | Rastreabilidade de onde veio cada dado |
| **Quarantine** | Dados que falharam validação, separados para revisão |
| **Serverless** | Serviços que escalam automaticamente sem gerenciar servidores |

---

## Regulação (Brasil)

| Regulador/Lei | Impacto |
|---|---|
| **SUSEP** | Superintendência de Seguros — regula seguradoras no Brasil |
| **LGPD** | Lei Geral de Proteção de Dados — exige proteção de dados pessoais |
| **IFRS 17** | Norma contábil internacional para contratos de seguro |
| **Circular SUSEP** | Normas específicas sobre reservas, reportes, solvência |
| **ANS** | Agência Nacional de Saúde (para planos de saúde) |

---

## Fórmulas Importantes

### Loss Ratio
```
Loss Ratio = Sinistros Incurred / Earned Premium × 100
```

### Combined Ratio
```
Combined Ratio = Loss Ratio + Expense Ratio
Expense Ratio = Despesas Operacionais / Earned Premium × 100
```

### Earned Premium (pro-rata diária)
```
Earned Premium Mensal = Written Premium × (dias no mês / dias total da apólice)
```

### Earned Premium (pro-rata mensal)
```
Earned Premium Mensal = Written Premium / Número de Meses da Apólice
```

### Claim Frequency
```
Claim Frequency = Número de Sinistros / Número de Apólices Expostas
```

### Average Claim Severity
```
Severity = Total Incurred / Número de Sinistros
```
