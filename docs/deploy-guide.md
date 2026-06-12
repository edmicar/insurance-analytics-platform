# Guia de Deploy

## Pré-requisitos

1. **AWS CLI** configurado com credenciais de administrador
2. **Terraform** >= 1.5 instalado
3. **Python** 3.9+ (para scripts auxiliares)

## Deploy Rápido (Dev)

```bash
# 1. Clone o repositório
git clone https://github.com/edmicar/insurance-analytics-platform.git
cd insurance-analytics-platform

# 2. Inicialize Terraform
cd terraform/environments/dev
terraform init

# 3. Visualize o que será criado
terraform plan

# 4. Aplique (cria todos os recursos)
terraform apply

# 5. Carregue dados de exemplo
cd ../../..
./scripts/load-sample-data.sh dev

# 6. Verifique no Athena
# Abra o Console AWS → Athena → Workgroup: insurancelake
# Execute: SELECT * FROM syntheticgeneraldata_consume.policydata LIMIT 100;
```

## Cleanup

```bash
cd terraform/environments/dev
terraform destroy
```

## Notas importantes

- O deploy cria ~20 recursos AWS
- Custo estimado: < $4 seguindo o workshop completo
- Região padrão: us-east-2 (Ohio)
- Sempre execute `terraform destroy` ao terminar para evitar custos
