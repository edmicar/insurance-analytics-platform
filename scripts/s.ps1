###############################################################################
# Insurance Analytics Platform - Setup S3 → Step Functions Trigger
#
# Cria uma Lambda function que é disparada por S3 ObjectCreated events
# no bucket Collect. A Lambda extrai metadados do path do arquivo e inicia
# a Step Functions state machine com os parâmetros corretos.
#
# Arquitetura:
#   S3 (ObjectCreated) → Lambda (trigger) → Step Functions → Glue Jobs
#
# PRÉ-REQUISITOS:
#   - AWS CLI configurado com credenciais válidas
#   - Terraform apply já executado (state machine deve existir)
#
# USO:
#   .\scripts\setup-s3-trigger.ps1
#
###############################################################################

param(
    [string]$Environment = "dev",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Setup S3 → Step Functions Trigger         " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$AccountId = (aws sts get-caller-identity --query Account --output text)
$CollectBucket = "$Environment-insurancelake-$AccountId-$Region-collect"
$StateMachineArn = "arn:aws:states:${Region}:${AccountId}:stateMachine:${Environment}-insurancelake-etl-state-machine"
$LambdaName = "$Environment-insurancelake-etl-trigger"
$RoleName = "$Environment-insurancelake-lambda-trigger-role"

Write-Host "Account:       $AccountId" -ForegroundColor Green
Write-Host "Bucket:        $CollectBucket" -ForegroundColor Green
Write-Host "State Machine: $StateMachineArn" -ForegroundColor Green
Write-Host "Lambda:        $LambdaName" -ForegroundColor Green
Write-Host ""

# ──────────────────────────────────────────────────────────────────────
# Passo 1: Criar IAM Role para Lambda
# ──────────────────────────────────────────────────────────────────────
Write-Host "[1/5] Criando IAM Role para Lambda..." -ForegroundColor Yellow

$trustPolicy = @'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
'@

try {
    aws iam create-role `
        --role-name $RoleName `
        --assume-role-policy-document $trustPolicy `
        --region $Region 2>$null | Out-Null
    Write-Host "  Role criada: $RoleName" -ForegroundColor Green
} catch {
    Write-Host "  Role já existe, continuando..." -ForegroundColor Gray
}

# Attach policies
$inlinePolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": ["states:StartExecution"],
      "Resource": "$StateMachineArn"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject","s3:GetObjectVersion"],
      "Resource": "arn:aws:s3:::$CollectBucket/*"
    }
  ]
}
"@

aws iam put-role-policy `
    --role-name $RoleName `
    --policy-name "${Environment}-insurancelake-lambda-trigger-policy" `
    --policy-document $inlinePolicy `
    --region $Region

Write-Host "  Policies attached" -ForegroundColor Green
Start-Sleep -Seconds 10  # Aguardar propagação IAM

# ──────────────────────────────────────────────────────────────────────
# Passo 2: Criar código da Lambda
# ──────────────────────────────────────────────────────────────────────
Write-Host "[2/5] Criando código da Lambda..." -ForegroundColor Yellow

$lambdaCode = @'
import json
import os
import boto3
from datetime import datetime
from urllib.parse import unquote_plus

sfn_client = boto3.client('stepfunctions')
STATE_MACHINE_ARN = os.environ['STATE_MACHINE_ARN']

def lambda_handler(event, context):
    """
    Triggered by S3 ObjectCreated event on the Collect bucket.
    Extracts metadata from the S3 key path and starts Step Functions.
    
    Expected S3 key format:
        <DatabaseName>/<TableName>/filename.csv
        <DatabaseName>/<TableName>/<year>/<month>/<day>/filename.csv (partition override)
    """
    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        
        print(f"Processing: s3://{bucket}/{key}")
        
        # Parse the S3 key to extract database and table names
        parts = key.split('/')
        
        if len(parts) < 3:
            print(f"Skipping: insufficient path depth ({len(parts)} levels). Need at least 3.")
            continue
        
        database_name = parts[0]
        table_name = parts[1]
        
        # Determine partition values
        now = datetime.utcnow()
        if len(parts) >= 6:
            # Partition override: DatabaseName/TableName/year/month/day/file
            year = parts[2]
            month = parts[3]
            day = parts[4]
        else:
            # Use current date
            year = str(now.year)
            month = str(now.month).zfill(2)
            day = str(now.day).zfill(2)
        
        # Build execution input
        execution_input = {
            "source_bucket": bucket,
            "source_key": key,
            "database_name": database_name.lower(),
            "table_name": table_name.lower(),
            "year": year,
            "month": month,
            "day": day
        }
        
        # Start Step Functions execution
        execution_name = f"{table_name}-{now.strftime('%Y%m%d%H%M%S%f')}"[:80]
        
        response = sfn_client.start_execution(
            stateMachineArn=STATE_MACHINE_ARN,
            name=execution_name,
            input=json.dumps(execution_input)
        )
        
        print(f"Started execution: {execution_name}")
        print(f"Input: {json.dumps(execution_input)}")
        print(f"Execution ARN: {response['executionArn']}")
    
    return {'statusCode': 200, 'body': 'Trigger processed successfully'}
'@

# Criar arquivo zip
$TempDir = "$env:TEMP\lambda-trigger"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
$lambdaCode | Out-File -FilePath "$TempDir\lambda_function.py" -Encoding utf8 -Force

# Criar ZIP
$ZipPath = "$env:TEMP\lambda-trigger.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path "$TempDir\lambda_function.py" -DestinationPath $ZipPath -Force

Write-Host "  Lambda code packaged" -ForegroundColor Green

# ──────────────────────────────────────────────────────────────────────
# Passo 3: Criar/Atualizar Lambda Function
# ──────────────────────────────────────────────────────────────────────
Write-Host "[3/5] Criando Lambda function..." -ForegroundColor Yellow

$RoleArn = "arn:aws:iam::${AccountId}:role/${RoleName}"

try {
    aws lambda create-function `
        --function-name $LambdaName `
        --runtime python3.12 `
        --role $RoleArn `
        --handler lambda_function.lambda_handler `
        --zip-file "fileb://$ZipPath" `
        --timeout 60 `
        --memory-size 128 `
        --environment "Variables={STATE_MACHINE_ARN=$StateMachineArn}" `
        --region $Region 2>$null | Out-Null
    Write-Host "  Lambda criada: $LambdaName" -ForegroundColor Green
} catch {
    Write-Host "  Lambda já existe, atualizando código..." -ForegroundColor Gray
    aws lambda update-function-code `
        --function-name $LambdaName `
        --zip-file "fileb://$ZipPath" `
        --region $Region | Out-Null
    aws lambda update-function-configuration `
        --function-name $LambdaName `
        --environment "Variables={STATE_MACHINE_ARN=$StateMachineArn}" `
        --region $Region | Out-Null
}

# ──────────────────────────────────────────────────────────────────────
# Passo 4: Dar permissão ao S3 para invocar Lambda
# ──────────────────────────────────────────────────────────────────────
Write-Host "[4/5] Configurando permissão S3 → Lambda..." -ForegroundColor Yellow

aws lambda add-permission `
    --function-name $LambdaName `
    --statement-id "s3-invoke-trigger" `
    --action "lambda:InvokeFunction" `
    --principal "s3.amazonaws.com" `
    --source-arn "arn:aws:s3:::$CollectBucket" `
    --source-account $AccountId `
    --region $Region 2>$null | Out-Null

Write-Host "  Permission granted: S3 → Lambda" -ForegroundColor Green

# ──────────────────────────────────────────────────────────────────────
# Passo 5: Configurar S3 Event Notification
# ──────────────────────────────────────────────────────────────────────
Write-Host "[5/5] Configurando S3 Event Notification..." -ForegroundColor Yellow

$LambdaArn = "arn:aws:lambda:${Region}:${AccountId}:function:${LambdaName}"

$notificationConfig = @"
{
  "LambdaFunctionConfigurations": [
    {
      "Id": "TriggerETLPipeline",
      "LambdaFunctionArn": "$LambdaArn",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {"Name": "suffix", "Value": ".csv"},
            {"Name": "prefix", "Value": ""}
          ]
        }
      }
    }
  ]
}
"@

$notificationConfig | Out-File -FilePath "$env:TEMP\s3-notification.json" -Encoding utf8 -Force

aws s3api put-bucket-notification-configuration `
    --bucket $CollectBucket `
    --notification-configuration "file://$env:TEMP\s3-notification.json" `
    --region $Region

Write-Host "  S3 notification configured: ObjectCreated:*.csv → Lambda" -ForegroundColor Green

# ──────────────────────────────────────────────────────────────────────
# Resultado
# ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " Trigger configurado com sucesso!          " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fluxo:" -ForegroundColor Cyan
Write-Host "  S3 Upload (.csv) → Lambda ($LambdaName) → Step Functions" -ForegroundColor White
Write-Host ""
Write-Host "Teste:" -ForegroundColor Cyan
Write-Host "  aws s3 cp sample-data/claim-data.csv s3://$CollectBucket/SyntheticGeneralData/ClaimData/" -ForegroundColor Gray
Write-Host ""
Write-Host "  Depois verifique Step Functions no Console → Deve ter execução nova." -ForegroundColor Gray
Write-Host ""

# Cleanup temp
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
