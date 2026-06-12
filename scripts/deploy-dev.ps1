###############################################################################
# Insurance Analytics Platform - Deploy Script (PowerShell)
# 
# USO:
#   1. Configure suas credenciais AWS no terminal:
#      $env:AWS_DEFAULT_REGION = "us-east-1"
#      $env:AWS_ACCESS_KEY_ID = "sua-key"
#      $env:AWS_SECRET_ACCESS_KEY = "sua-secret"
#      $env:AWS_SESSION_TOKEN = "seu-token"  (se usar sessão temporária)
#
#   2. Execute este script:
#      .\scripts\deploy-dev.ps1
#
###############################################################################

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Insurance Analytics Platform - Deploy Dev  " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Validar credenciais
Write-Host "[1/5] Validando credenciais AWS..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity | ConvertFrom-Json
    Write-Host "  Account: $($identity.Account)" -ForegroundColor Green
    Write-Host "  User:    $($identity.Arn)" -ForegroundColor Green
    Write-Host "  Region:  $env:AWS_DEFAULT_REGION" -ForegroundColor Green
} catch {
    Write-Host "  ERRO: Credenciais inválidas ou expiradas." -ForegroundColor Red
    Write-Host "  Configure as variáveis de ambiente AWS antes de rodar este script." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Verificar Terraform
Write-Host "[2/5] Verificando Terraform..." -ForegroundColor Yellow
$tf = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $tf) {
    Write-Host "  ERRO: Terraform não encontrado no PATH." -ForegroundColor Red
    Write-Host "  Instale: https://developer.hashicorp.com/terraform/downloads" -ForegroundColor Red
    exit 1
}
$tfVersion = terraform version -json | ConvertFrom-Json
Write-Host "  Terraform: $($tfVersion.terraform_version)" -ForegroundColor Green
Write-Host ""

# Terraform Init
Write-Host "[3/5] Inicializando Terraform..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\..\terraform\environments\dev"
terraform init -input=false
if ($LASTEXITCODE -ne 0) { Write-Host "  ERRO no terraform init" -ForegroundColor Red; exit 1 }
Write-Host ""

# Terraform Plan
Write-Host "[4/5] Gerando plano de execução..." -ForegroundColor Yellow
terraform plan -out=tfplan -input=false
if ($LASTEXITCODE -ne 0) { Write-Host "  ERRO no terraform plan" -ForegroundColor Red; exit 1 }
Write-Host ""

# Terraform Apply
Write-Host "[5/5] Aplicando infraestrutura..." -ForegroundColor Yellow
$confirm = Read-Host "  Deseja aplicar o plano acima? (yes/no)"
if ($confirm -eq "yes") {
    terraform apply tfplan
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "============================================" -ForegroundColor Green
        Write-Host " Deploy concluído com sucesso!              " -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Próximos passos:" -ForegroundColor Cyan
        Write-Host "  1. Carregue dados de exemplo: .\scripts\load-sample-data.ps1"
        Write-Host "  2. Abra o Athena no Console AWS (workgroup: insurancelake)"
        Write-Host "  3. Execute: SELECT * FROM syntheticgeneraldata_consume.policydata LIMIT 100;"
        Write-Host ""
        Write-Host "Para limpar recursos: terraform destroy" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Deploy cancelado pelo usuário." -ForegroundColor Yellow
}

# Voltar ao diretório original
Set-Location "$PSScriptRoot\.."

# Limpar arquivo de plano
Remove-Item "$PSScriptRoot\..\terraform\environments\dev\tfplan" -ErrorAction SilentlyContinue
