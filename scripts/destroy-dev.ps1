###############################################################################
# Insurance Analytics Platform - Destroy Script (PowerShell)
#
# ATENÇÃO: Este script remove TODOS os recursos criados pelo Terraform.
# Execute APENAS quando tiver certeza de que não precisa mais do ambiente.
###############################################################################

Write-Host "============================================" -ForegroundColor Red
Write-Host " Insurance Analytics Platform - DESTROY Dev " -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Red
Write-Host ""
Write-Host "ATENÇÃO: Isso vai remover TODOS os recursos AWS deste projeto!" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Digite 'DESTROY' para confirmar"
if ($confirm -ne "DESTROY") {
    Write-Host "Operação cancelada." -ForegroundColor Yellow
    exit 0
}

Set-Location "$PSScriptRoot\..\terraform\environments\dev"
terraform destroy -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Todos os recursos foram removidos com sucesso." -ForegroundColor Green
    Write-Host "Custo contínuo: $0.00" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "ERRO durante a destruição. Verifique o Console AWS." -ForegroundColor Red
    Write-Host "Pode ser necessário esvaziar buckets S3 manualmente antes de destruir." -ForegroundColor Yellow
}

Set-Location "$PSScriptRoot\.."
