# Reasoning Case: InsuranceLake

## O Problema de Negócio — Explicado de Forma Didática

---

## 🎯 Em uma frase

> Uma seguradora tem dados espalhados em vários sistemas, não consegue cruzar informações de apólices com sinistros, e por isso **não sabe se está ganhando ou perdendo dinheiro** em cada linha de negócio.

---

## 📖 A História (Contexto de Negócio)

Imagine que você é o diretor financeiro de uma seguradora chamada **"SeguraTudo"**.

A SeguraTudo vende vários tipos de seguro:
- 🚗 Auto
- 🏠 Residencial
- 💼 Empresarial
- ⚕️ Saúde

### O dia-a-dia da SeguraTudo

Cada departamento usa um sistema diferente:

```
┌─────────────────────────────────────────────────────────────┐
│                    SEGURADORA "SeguraTudo"                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  📋 Sistema de Apólices     → Guidewire PolicyCenter         │
│     (quem comprou, quanto paga, qual cobertura)              │
│                                                              │
│  🚨 Sistema de Sinistros    → Duck Creek Claims              │
│     (quem teve acidente, quanto custou)                      │
│                                                              │
│  💰 Sistema Financeiro      → SAP                            │
│     (faturamento, comissões, impostos)                       │
│                                                              │
│  📞 Sistema de Atendimento  → Salesforce                     │
│     (reclamações, NPS, histórico do cliente)                 │
│                                                              │
│  📊 Planilhas Excel         → Atuários e analistas           │
│     (cálculos manuais, relatórios ad-hoc)                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### O problema real

O diretor financeiro faz uma pergunta simples:

> **"Qual o nosso Loss Ratio (índice de sinistralidade) por linha de negócio nos últimos 12 meses?"**

E a resposta demora **3 semanas** porque:

1. O analista precisa pedir um export do sistema de apólices (CSV com 500k linhas)
2. Pedir outro export do sistema de sinistros (outro CSV, formato diferente)
3. Abrir no Excel e tentar fazer VLOOKUP entre os dois
4. Os campos não batem: um usa "PolicyNo" e outro usa "POLICY_NUMBER"
5. As datas estão em formatos diferentes: "01/15/2024" vs "2024-01-15"
6. O Excel trava com 500k linhas
7. O analista pede ajuda da TI, que leva mais uma semana
8. O resultado final pode ter erros porque o processo é manual

---

## 💡 A Solução: InsuranceLake

O InsuranceLake resolve este problema criando um **pipeline automatizado** que:

```
ANTES (Manual, 3 semanas):
━━━━━━━━━━━━━━━━━━━━━━━━━
Sistema A ──export──▶ CSV ──email──▶ Analista ──Excel──▶ Relatório (com erros)
Sistema B ──export──▶ CSV ─────────────┘

DEPOIS (Automatizado, minutos):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sistema A ──arquivo──▶ ┌────────────────────────┐
                       │     InsuranceLake       │──▶ Dashboard em tempo real
Sistema B ──arquivo──▶ │  (limpa, cruza, calcula)│──▶ SQL query instantâneo
                       └────────────────────────┘──▶ Relatório regulatório
```

---

## 🔑 Conceitos-Chave do Negócio de Seguros

### O que é uma Apólice (Policy)?

É o **contrato** entre a seguradora e o cliente:
- Quem é o segurado
- O que está coberto (auto, casa, vida)
- Quanto o cliente paga (**prêmio** / premium)
- De quando até quando vale (effective date → expiration date)
- Qual o limite de cobertura

### O que é um Sinistro (Claim)?

É o **evento** que aciona o seguro:
- Cliente bateu o carro → abre um sinistro
- Casa pegou fogo → abre um sinistro
- O custo do sinistro é o **incurred amount** (quanto a seguradora pagou ou vai pagar)

### O que é Loss Ratio (Índice de Sinistralidade)?

A **métrica mais importante** de uma seguradora:

```
                    Total de Sinistros Pagos
Loss Ratio = ─────────────────────────────────
                    Total de Prêmio Ganho

Exemplo:
- A seguradora recebeu R$ 10.000.000 em prêmios (Earned Premium)
- Pagou R$ 7.000.000 em sinistros (Incurred Claims)
- Loss Ratio = 70%
```

**Interpretação:**
- < 60% → Muito lucrativo (talvez preço alto demais, perdendo clientes)
- 60-75% → Saudável
- 75-90% → Atenção
- > 100% → **Prejuízo** (pagando mais em sinistros do que recebe em prêmios)

### O que é Earned Premium (Prêmio Ganho)?

O prêmio não é "ganho" todo de uma vez. É ganho **proporcionalmente ao tempo**:

```
Apólice: Jan/2024 a Dez/2024
Prêmio Total: R$ 12.000

Em Janeiro, a seguradora "ganhou" apenas R$ 1.000 (1/12)
Em Fevereiro, mais R$ 1.000
...
Em Dezembro, completa os R$ 12.000

Se o cliente cancelar em Junho, a seguradora ganhou R$ 6.000
e deve devolver R$ 6.000.
```

**Por que isso importa?** Porque não se pode comparar prêmios escritos (total vendido) com sinistros pagos. Precisa usar prêmio **ganho** para ter a comparação justa.

### O que é Written Premium (Prêmio Escrito)?

É o valor **total** do contrato no momento da venda:
- Vendeu apólice de R$ 12.000/ano → Written Premium = R$ 12.000
- É registrado integralmente na data da venda
- Diferente do Earned Premium que é proporcional ao tempo

### New vs Renewal

- **New:** Cliente novo comprando pela primeira vez
- **Renewal:** Cliente existente renovando a apólice
- Renovações são mais baratas (sem custo de aquisição) e mais previsíveis

---

## 📊 As Perguntas que o InsuranceLake Responde

### Para o CFO (Diretor Financeiro)
| Pergunta | Dados necessários |
|---|---|
| "Qual nosso loss ratio por LOB?" | Policy + Claims (JOIN) |
| "Estamos crescendo ou encolhendo?" | Written Premium por mês |
| "Qual o mix new vs renewal?" | Policy com flag New/Renewal |

### Para o Atuário
| Pergunta | Dados necessários |
|---|---|
| "Qual o desenvolvimento de sinistros por ano de acidente?" | Claims com accident year |
| "Qual a frequência de sinistros por cobertura?" | Claims / Policy count |
| "Quanto de reserva técnica precisamos?" | Claims incurred + padrão de desenvolvimento |

### Para o Underwriter (Subscritor)
| Pergunta | Dados necessários |
|---|---|
| "Quais apólices têm loss ratio acima de 80%?" | Policy + Claims por policy |
| "Qual região tem mais sinistros?" | Claims com geolocalização |
| "Devo renovar esta apólice?" | Histórico Policy + Claims do cliente |

### Para o Regulador (SUSEP no Brasil)
| Pergunta | Dados necessários |
|---|---|
| "Qual o volume de prêmio por ramo?" | Policy agregado por LOB |
| "Qual a reserva de sinistros a liquidar?" | Claims com status open |
| "Prazo médio de liquidação de sinistros?" | Claims com datas de abertura/fechamento |

---

## 🏗️ O que o InsuranceLake Faz Tecnicamente para Resolver

### Passo 1: Coletar (Collect)
- Recebe arquivos dos sistemas fonte (CSV, JSON, Excel, Parquet)
- Não importa o formato ou a bagunça — aceita como veio
- Armazena o original intacto (auditoria)

### Passo 2: Limpar (Cleanse)
- Renomeia colunas ("Policy No" → "policynumber")
- Converte tipos ("01/15/2024" → 2024-01-15 como DATE)
- Padroniza valores ("São Paulo", "SP", "Sao Paulo" → "SP")
- Tokeniza dados sensíveis (CPF, email → hash)
- Valida qualidade (prêmio negativo? data futura? campo vazio?)
- Quarentena dados corrompidos (para revisão humana)

### Passo 3: Consumir (Consume)
- Cruza Policy com Claims (JOIN por PolicyNumber)
- Calcula métricas: Earned Premium, Loss Ratio, Months Active
- Expande para granularidade mensal (1 linha/mês/apólice)
- Cria views para cada público (CFO, atuário, regulador)
- Alimenta dashboards (QuickSight) e queries ad-hoc (Athena)

---

## 💰 Valor de Negócio Gerado

| Antes | Depois |
|---|---|
| 3 semanas para um relatório | Minutos (query SQL) |
| Dados inconsistentes entre áreas | Single source of truth |
| Cálculos manuais em Excel | Cálculos automatizados e auditáveis |
| Não sabe loss ratio por LOB | Dashboard real-time por LOB |
| Reportes regulatórios atrasados | Geração automática |
| Decisões baseadas em intuição | Decisões baseadas em dados |
| Risco de erros humanos | Validação automática (Data Quality) |
| Dados sensíveis em planilhas | PII tokenizado e controlado |

---

## 🎓 Por que isso importa para um Engenheiro Sênior?

Um engenheiro sênior não apenas "faz o pipeline funcionar". Ele:

1. **Entende o problema de negócio** — sabe o que é Loss Ratio, Earned Premium, por que importa
2. **Traduz para solução técnica** — escolhe os serviços certos para cada problema
3. **Pensa em escala** — "e se forem 100 seguradoras? 1 bilhão de linhas?"
4. **Cuida de qualidade** — implementa Data Quality rules que fazem sentido no contexto de seguros
5. **Considera regulação** — sabe que SUSEP, LGPD e IFRS 17 impactam a arquitetura
6. **Comunica com stakeholders** — explica decisões técnicas em termos de negócio
7. **Documenta decisões** — registra "por quê" além de "como"

---

## 📐 Analogia Final

Pense no InsuranceLake como um **restaurante industrial**:

| Analogia | InsuranceLake |
|---|---|
| Ingredientes brutos (farinha, carne, legumes) | Dados brutos (CSV, JSON, Excel) |
| Recebimento e inspeção de qualidade | Collect bucket + Lambda trigger |
| Cozinha (lavar, cortar, temperar) | Cleanse (schema mapping + transforms) |
| Pratos montados e prontos para servir | Consume bucket (Parquet particionado) |
| Cardápio (menu do dia) | Glue Data Catalog (catálogo de dados) |
| Garçom que atende pedidos | Athena (queries SQL sob demanda) |
| Painel da cozinha mostrando pedidos | QuickSight dashboards |
| Nutricionista verificando se tá saudável | Data Quality rules |
| Receita escrita (reproduzível) | Transform specs em JSON (IaC) |
