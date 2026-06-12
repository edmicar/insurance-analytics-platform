#!/bin/bash
###############################################################################
# Insurance Analytics Platform - Setup S3 → Step Functions Trigger
#
# Cria Lambda function disparada por S3 ObjectCreated no bucket Collect.
# Roda no AWS CloudShell (credenciais já configuradas automaticamente).
#
# USO:
#   chmod +x scripts/setup-s3-trigger.sh
#   ./scripts/setup-s3-trigger.sh
#
###############################################################################

set -e

ENVIRONMENT="dev"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
COLLECT_BUCKET="${ENVIRONMENT}-insurancelake-${ACCOUNT_ID}-${REGION}-collect"
STATE_MACHINE_ARN="arn:aws:states:${REGION}:${ACCOUNT_ID}:stateMachine:${ENVIRONMENT}-insurancelake-etl-state-machine"
LAMBDA_NAME="${ENVIRONMENT}-insurancelake-etl-trigger"
ROLE_NAME="${ENVIRONMENT}-insurancelake-lambda-trigger-role"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_NAME}"

echo "============================================"
echo " Setup S3 → Step Functions Trigger"
echo "============================================"
echo ""
echo "Account:       $ACCOUNT_ID"
echo "Bucket:        $COLLECT_BUCKET"
echo "State Machine: $STATE_MACHINE_ARN"
echo "Lambda:        $LAMBDA_NAME"
echo ""

# ──────────────────────────────────────────────────────────────────────
# Passo 1: Criar IAM Role
# ──────────────────────────────────────────────────────────────────────
echo "[1/5] Criando IAM Role para Lambda..."

cat > /tmp/trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file:///tmp/trust-policy.json \
    2>/dev/null || echo "  Role já existe, continuando..."

cat > /tmp/lambda-policy.json << EOF
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
      "Resource": "$STATE_MACHINE_ARN"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject","s3:GetObjectVersion"],
      "Resource": "arn:aws:s3:::$COLLECT_BUCKET/*"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "${ENVIRONMENT}-insurancelake-lambda-trigger-policy" \
    --policy-document file:///tmp/lambda-policy.json

echo "  Role configurada ✓"
echo "  Aguardando propagação IAM (10s)..."
sleep 10

# ──────────────────────────────────────────────────────────────────────
# Passo 2: Criar código Lambda
# ──────────────────────────────────────────────────────────────────────
echo "[2/5] Criando código da Lambda..."

mkdir -p /tmp/lambda-trigger
cat > /tmp/lambda-trigger/lambda_function.py << 'PYTHON'
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
        <DatabaseName>/<TableName>/<year>/<month>/<day>/filename.csv
    """
    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        
        print(f"Processing: s3://{bucket}/{key}")
        
        parts = key.split('/')
        
        if len(parts) < 3:
            print(f"Skipping: insufficient path depth ({len(parts)} levels)")
            continue
        
        database_name = parts[0]
        table_name = parts[1]
        
        now = datetime.utcnow()
        if len(parts) >= 6:
            year = parts[2]
            month = parts[3]
            day = parts[4]
        else:
            year = str(now.year)
            month = str(now.month).zfill(2)
            day = str(now.day).zfill(2)
        
        execution_input = {
            "source_bucket": bucket,
            "source_key": key,
            "database_name": database_name.lower(),
            "table_name": table_name.lower(),
            "year": year,
            "month": month,
            "day": day
        }
        
        execution_name = f"{table_name}-{now.strftime('%Y%m%d%H%M%S%f')}"[:80]
        
        response = sfn_client.start_execution(
            stateMachineArn=STATE_MACHINE_ARN,
            name=execution_name,
            input=json.dumps(execution_input)
        )
        
        print(f"Started execution: {execution_name}")
        print(f"Input: {json.dumps(execution_input)}")
    
    return {'statusCode': 200, 'body': 'OK'}
PYTHON

cd /tmp/lambda-trigger && zip -j /tmp/lambda-trigger.zip lambda_function.py
cd -
echo "  Lambda packaged ✓"

# ──────────────────────────────────────────────────────────────────────
# Passo 3: Criar Lambda Function
# ──────────────────────────────────────────────────────────────────────
echo "[3/5] Criando Lambda function..."

aws lambda create-function \
    --function-name "$LAMBDA_NAME" \
    --runtime python3.12 \
    --role "$ROLE_ARN" \
    --handler lambda_function.lambda_handler \
    --zip-file fileb:///tmp/lambda-trigger.zip \
    --timeout 60 \
    --memory-size 128 \
    --environment "Variables={STATE_MACHINE_ARN=$STATE_MACHINE_ARN}" \
    --region "$REGION" \
    2>/dev/null || {
        echo "  Lambda já existe, atualizando..."
        aws lambda update-function-code \
            --function-name "$LAMBDA_NAME" \
            --zip-file fileb:///tmp/lambda-trigger.zip \
            --region "$REGION" > /dev/null
        sleep 5
        aws lambda update-function-configuration \
            --function-name "$LAMBDA_NAME" \
            --environment "Variables={STATE_MACHINE_ARN=$STATE_MACHINE_ARN}" \
            --region "$REGION" > /dev/null
    }

echo "  Lambda criada ✓"

# ──────────────────────────────────────────────────────────────────────
# Passo 4: Permissão S3 → Lambda
# ──────────────────────────────────────────────────────────────────────
echo "[4/5] Configurando permissão S3 → Lambda..."

aws lambda add-permission \
    --function-name "$LAMBDA_NAME" \
    --statement-id "s3-invoke-trigger" \
    --action "lambda:InvokeFunction" \
    --principal "s3.amazonaws.com" \
    --source-arn "arn:aws:s3:::$COLLECT_BUCKET" \
    --source-account "$ACCOUNT_ID" \
    --region "$REGION" \
    2>/dev/null || echo "  Permission já existe"

echo "  Permission configurada ✓"

# ──────────────────────────────────────────────────────────────────────
# Passo 5: S3 Event Notification
# ──────────────────────────────────────────────────────────────────────
echo "[5/5] Configurando S3 Event Notification..."

cat > /tmp/s3-notification.json << EOF
{
  "LambdaFunctionConfigurations": [
    {
      "Id": "TriggerETLPipeline",
      "LambdaFunctionArn": "$LAMBDA_ARN",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {"Name": "suffix", "Value": ".csv"}
          ]
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-notification-configuration \
    --bucket "$COLLECT_BUCKET" \
    --notification-configuration file:///tmp/s3-notification.json \
    --region "$REGION"

echo "  S3 notification configurada ✓"

# ──────────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo " TRIGGER CONFIGURADO COM SUCESSO!"
echo "============================================"
echo ""
echo "Fluxo: S3 (.csv upload) → Lambda → Step Functions → Glue"
echo ""
echo "TESTE:"
echo "  aws s3 cp sample-data/claim-data.csv s3://$COLLECT_BUCKET/SyntheticGeneralData/ClaimData/"
echo ""
echo "VERIFICAR:"
echo "  Console → Step Functions → Executions (deve aparecer nova execução)"
echo ""

# Cleanup
rm -rf /tmp/lambda-trigger /tmp/lambda-trigger.zip /tmp/trust-policy.json /tmp/lambda-policy.json /tmp/s3-notification.json
