###############################################################################
# Insurance Analytics Platform - Load Sample Data
#
# Carrega dados de exemplo no pipeline:
# 1. Lookup data no DynamoDB
# 2. Claim data no S3 Collect bucket
# 3. Policy data no S3 Collect bucket
#
# PRÉ-REQUISITOS:
#   - AWS CLI configurado com credenciais válidas
#   - ETL scripts já sincronizados (rodar sync-etl-scripts.ps1 primeiro)
#
# USO:
#   .\scripts\load-sample-data.ps1
#
###############################################################################

param(
    [string]$Environment = "dev",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Load Sample Data                          " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$AccountId = (aws sts get-caller-identity --query Account --output text)
$CollectBucket = "$Environment-insurancelake-$AccountId-$Region-collect"
$LookupTable = "$Environment-insurancelake-etl-value-lookup"

Write-Host "Account:        $AccountId" -ForegroundColor Green
Write-Host "Collect Bucket: $CollectBucket" -ForegroundColor Green
Write-Host "Lookup Table:   $LookupTable" -ForegroundColor Green
Write-Host ""

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot

# ──────────────────────────────────────────────────────────────────────
# Passo 1: Carregar lookup data no DynamoDB
# ──────────────────────────────────────────────────────────────────────
Write-Host "[1/3] Carregando lookup data no DynamoDB..." -ForegroundColor Yellow

$lookups = Get-Content "$ProjectRoot\sample-data\lookup-data.json" | ConvertFrom-Json

foreach ($columnName in $lookups.PSObject.Properties.Name) {
    $lookupValues = $lookups.$columnName
    
    # Construir item DynamoDB
    $item = @{
        source_system = @{ S = "SyntheticGeneralData" }
        column_name   = @{ S = $columnName }
    }
    
    foreach ($key in $lookupValues.PSObject.Properties.Name) {
        $item[$key] = @{ S = $lookupValues.$key }
    }
    
    $itemJson = ($item | ConvertTo-Json -Compress -Depth 5)
    aws dynamodb put-item --table-name $LookupTable --item $itemJson --region $Region 2>$null
    Write-Host "  Loaded lookup: $columnName ($($lookupValues.PSObject.Properties.Count) values)" -ForegroundColor Gray
}
Write-Host ""

# ──────────────────────────────────────────────────────────────────────
# Passo 2: Upload Claim Data → Dispara pipeline automaticamente
# ──────────────────────────────────────────────────────────────────────
Write-Host "[2/3] Uploading claim data..." -ForegroundColor Yellow
Write-Host "  NOTA: Isso dispara o pipeline ETL automaticamente (se Lambda trigger estiver ativo)" -ForegroundColor Gray

aws s3 cp "$ProjectRoot\sample-data\claim-data.csv" `
    "s3://$CollectBucket/SyntheticGeneralData/ClaimData/" --region $Region

Write-Host "  Uploaded: claim-data.csv → SyntheticGeneralData/ClaimData/" -ForegroundColor Green
Write-Host ""

# Aguardar processamento do claim antes de subir policy (dependência)
Write-Host "  Aguardando 10 segundos antes de subir policy data (dependência)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# ──────────────────────────────────────────────────────────────────────
# Passo 3: Upload Policy Data
# ──────────────────────────────────────────────────────────────────────
Write-Host "[3/3] Uploading policy data..." -ForegroundColor Yellow

aws s3 cp "$ProjectRoot\sample-data\policy-data.csv" `
    "s3://$CollectBucket/SyntheticGeneralData/PolicyData/" --region $Region

Write-Host "  Uploaded: policy-data.csv → SyntheticGeneralData/PolicyData/" -ForegroundColor Green
Write-Host ""

# ──────────────────────────────────────────────────────────────────────
# Resumo
# ──────────────────────────────────────────────────────────────────────
Write-Host "============================================" -ForegroundColor Green
Write-Host " Dados carregados com sucesso!             " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Verificar Step Functions:" -ForegroundColor White
Write-Host "     Console → Step Functions → dev-insurancelake-etl-state-machine"
Write-Host ""
Write-Host "  2. Se pipeline não disparou automaticamente, execute manualmente:" -ForegroundColor White
Write-Host "     aws stepfunctions start-execution \" -ForegroundColor Gray
Write-Host "       --state-machine-arn arn:aws:states:${Region}:${AccountId}:stateMachine:dev-insurancelake-etl-state-machine \" -ForegroundColor Gray
Write-Host "       --input '{`"source_bucket`":`"$CollectBucket`",`"source_key`":`"SyntheticGeneralData/ClaimData/claim-data.csv`",`"database_name`":`"syntheticgeneraldata`",`"table_name`":`"claimdata`",`"year`":`"2024`",`"month`":`"06`",`"day`":`"12`"}'" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Após pipeline completar, consulte no Athena:" -ForegroundColor White
Write-Host "     SELECT * FROM syntheticgeneraldata_consume.claimdata LIMIT 100;" -ForegroundColor Gray
Write-Host ""
