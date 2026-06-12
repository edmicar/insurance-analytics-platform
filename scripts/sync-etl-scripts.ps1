###############################################################################
# Insurance Analytics Platform - Sync ETL Scripts to S3
#
# Este script clona o repositório original da AWS InsuranceLake e faz upload
# dos scripts PySpark e configurações para o bucket etl-scripts.
#
# PRÉ-REQUISITOS:
#   - AWS CLI configurado com credenciais válidas
#   - Git disponível no PATH
#   - Variáveis de ambiente AWS configuradas (ou profile)
#
# USO:
#   .\scripts\sync-etl-scripts.ps1
#
###############################################################################

param(
    [string]$Environment = "dev",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Sync ETL Scripts to S3                    " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Obter Account ID
$AccountId = (aws sts get-caller-identity --query Account --output text)
$EtlBucket = "$Environment-insurancelake-etl-scripts"

Write-Host "Account:    $AccountId" -ForegroundColor Green
Write-Host "Bucket:     $EtlBucket" -ForegroundColor Green
Write-Host "Region:     $Region" -ForegroundColor Green
Write-Host ""

# Clonar repo da AWS se não existir
$TempDir = "$env:TEMP\aws-insurancelake-etl"
if (Test-Path $TempDir) {
    Write-Host "[1/4] Repositório já clonado, atualizando..." -ForegroundColor Yellow
    Push-Location $TempDir
    git pull --quiet
    Pop-Location
} else {
    Write-Host "[1/4] Clonando repositório AWS InsuranceLake ETL..." -ForegroundColor Yellow
    git clone --depth 1 https://github.com/aws-solutions-library-samples/aws-insurancelake-etl.git $TempDir
}
Write-Host ""

# Upload dos Glue Scripts (PySpark)
Write-Host "[2/4] Uploading Glue PySpark scripts..." -ForegroundColor Yellow
aws s3 cp "$TempDir\lib\glue_scripts\etl_collect_to_cleanse.py" "s3://$EtlBucket/etl/glue-scripts/collect_to_cleanse.py"
aws s3 cp "$TempDir\lib\glue_scripts\etl_cleanse_to_consume.py" "s3://$EtlBucket/etl/glue-scripts/cleanse_to_consume.py"

# Upload da lib de transforms
Write-Host "[3/4] Uploading transform libraries..." -ForegroundColor Yellow
aws s3 sync "$TempDir\lib\glue_scripts\lib" "s3://$EtlBucket/etl/glue-scripts/lib/" --quiet

# Upload das configurações (transformation-spec, dq-rules, sql)
Write-Host "[4/4] Uploading ETL configurations..." -ForegroundColor Yellow
aws s3 sync "$TempDir\lib\glue_scripts\transformation-spec" "s3://$EtlBucket/etl/transformation-spec/" --quiet
aws s3 sync "$TempDir\lib\glue_scripts\dq-rules" "s3://$EtlBucket/etl/dq-rules/" --quiet
aws s3 sync "$TempDir\lib\glue_scripts\transformation-sql" "s3://$EtlBucket/etl/transformation-sql/" --quiet

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " Scripts sincronizados com sucesso!        " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Estrutura no S3:" -ForegroundColor Cyan
Write-Host "  s3://$EtlBucket/"
Write-Host "  ├── etl/glue-scripts/"
Write-Host "  │   ├── collect_to_cleanse.py"
Write-Host "  │   ├── cleanse_to_consume.py"
Write-Host "  │   └── lib/ (transforms, helpers)"
Write-Host "  ├── etl/transformation-spec/ (schema mapping, transform configs)"
Write-Host "  ├── etl/dq-rules/ (data quality rules)"
Write-Host "  └── etl/transformation-sql/ (Spark SQL, Athena SQL)"
Write-Host ""
Write-Host "Próximo passo: Carregar dados de exemplo com:" -ForegroundColor Yellow
Write-Host "  .\scripts\load-sample-data.ps1" -ForegroundColor Yellow
