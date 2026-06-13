# QuickSight — Perguntas para Amazon Q (Natural Language)

## Após criar o dataset e abrir um Analysis, use a barra Q para perguntar:

### Perguntas sobre Prêmios (Premium)
```
Show total written premium by month
What is the total premium by line of business?
Compare written premium between new and renewal policies
Show premium trend over time
Which state has the highest premium?
Top 10 policies by premium amount
Average premium by line of business
```

### Perguntas sobre Sinistros (Claims)
```
Show total claims by month
What is the average claim amount?
How many claims by status?
Show claims by type
Which policies have the most claims?
Total incurred amount by line of business
Claims trend over time
```

### Perguntas sobre Loss Ratio
```
What is the loss ratio by line of business?
Show loss ratio trend over time
Which state has the worst loss ratio?
Compare loss ratio new vs renewal
Policies with loss ratio above 80%
```

### Perguntas sobre Distribuição
```
How many policies are new vs renewal?
Policy count by state
Distribution of premium amounts
Claims count by month
```

---

## Calculated Fields (criar no Dataset)

### Loss Ratio
```
sum({accidentyeartotalincurredamount}) / sum({writtenpremiumamount})
```

### Premium Category
```
ifelse(
  {writtenpremiumamount} > 20000, "High",
  ifelse({writtenpremiumamount} > 10000, "Medium", "Low")
)
```

### Claim Severity
```
ifelse(
  {accidentyeartotalincurredamount} > 30000, "Severe",
  ifelse({accidentyeartotalincurredamount} > 10000, "Moderate", "Low")
)
```

### Is Profitable
```
ifelse(
  {accidentyeartotalincurredamount} / {writtenpremiumamount} < 0.7,
  "Yes", "No"
)
```
