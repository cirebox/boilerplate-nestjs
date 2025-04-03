# Módulo para rotação automática de credenciais do Digital Ocean
# Este módulo implementa um sistema que rotaciona periodicamente tokens e credenciais
# usando funções AWS Lambda para garantir a segurança contínua da infraestrutura

locals {
  schedule_expression = var.rotation_schedule != "" ? var.rotation_schedule : "cron(0 0 1 * ? *)" # Padrão: 1º dia de cada mês
  function_name       = "${var.environment}-${var.project_name}-credential-rotation"

  # Script Python que será executado pela função Lambda para rotacionar credenciais
  lambda_function_code = <<EOF
import boto3
import json
import os
import requests
import logging
from datetime import datetime

# Configuração de logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Constantes
DIGITALOCEAN_API_URL = "https://api.digitalocean.com/v2"
SECRET_NAME = os.environ['SECRET_NAME']
NOTIFICATION_TOPIC = os.environ.get('SNS_TOPIC_ARN', '')

def get_secret():
    """Recupera o segredo atual do AWS Secrets Manager"""
    secrets_client = boto3.client('secretsmanager')
    try:
        response = secrets_client.get_secret_value(SecretId=SECRET_NAME)
        return json.loads(response['SecretString'])
    except Exception as e:
        logger.error(f"Erro ao recuperar segredo: {str(e)}")
        raise

def update_secret(secret_data):
    """Atualiza o segredo no AWS Secrets Manager"""
    secrets_client = boto3.client('secretsmanager')
    try:
        secrets_client.update_secret(
            SecretId=SECRET_NAME,
            SecretString=json.dumps(secret_data)
        )
        logger.info(f"Segredo atualizado com sucesso: {SECRET_NAME}")
    except Exception as e:
        logger.error(f"Erro ao atualizar segredo: {str(e)}")
        raise

def create_digitalocean_token(current_token):
    """Cria um novo token na Digital Ocean"""
    headers = {
        "Authorization": f"Bearer {current_token}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "name": f"terraform-token-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
        "scopes": ["read", "write"],
        "ttl": 2592000  # 30 dias em segundos
    }
    
    try:
        response = requests.post(
            f"{DIGITALOCEAN_API_URL}/tokens",
            headers=headers,
            json=payload
        )
        
        if response.status_code == 201:
            new_token = response.json()["token"]["token"]
            logger.info("Novo token criado com sucesso")
            return new_token
        else:
            logger.error(f"Falha ao criar token: {response.status_code} - {response.text}")
            raise Exception(f"Falha na API Digital Ocean: {response.status_code}")
            
    except Exception as e:
        logger.error(f"Erro na solicitação: {str(e)}")
        raise

def revoke_digitalocean_token(token_id, current_token):
    """Revoga um token existente da Digital Ocean"""
    headers = {
        "Authorization": f"Bearer {current_token}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.delete(
            f"{DIGITALOCEAN_API_URL}/tokens/{token_id}",
            headers=headers
        )
        
        if response.status_code == 204:
            logger.info(f"Token {token_id} revogado com sucesso")
            return True
        else:
            logger.error(f"Falha ao revogar token: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        logger.error(f"Erro na solicitação: {str(e)}")
        return False

def send_notification(message, subject="Rotação de Credenciais DigitalOcean"):
    """Envia notificação pelo SNS"""
    if not NOTIFICATION_TOPIC:
        logger.info("Tópico SNS não configurado, pulando notificação")
        return
        
    sns_client = boto3.client('sns')
    try:
        sns_client.publish(
            TopicArn=NOTIFICATION_TOPIC,
            Message=message,
            Subject=subject
        )
        logger.info("Notificação enviada com sucesso")
    except Exception as e:
        logger.error(f"Erro ao enviar notificação: {str(e)}")

def lambda_handler(event, context):
    """Função principal que gerencia a rotação de credenciais"""
    try:
        # Recupera as credenciais atuais
        secret_data = get_secret()
        current_token = secret_data.get("digitalocean_token")
        current_token_id = secret_data.get("digitalocean_token_id", "")
        
        if not current_token:
            raise Exception("Token da Digital Ocean não encontrado no segredo")
            
        # Cria um novo token
        new_token = create_digitalocean_token(current_token)
        
        # Atualiza o segredo com o novo token
        secret_data["previous_digitalocean_token"] = current_token
        secret_data["digitalocean_token"] = new_token
        secret_data["last_rotated"] = datetime.now().isoformat()
        
        # Guarda o segredo atualizado
        update_secret(secret_data)
        
        # Revoga o token antigo (se houver ID)
        if current_token_id:
            revoke_digitalocean_token(current_token_id, new_token)
            
        # Envia notificação
        send_notification(
            f"As credenciais da Digital Ocean foram rotacionadas com sucesso em {datetime.now().isoformat()}."
        )
        
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Rotação de credenciais concluída com sucesso"})
        }
        
    except Exception as e:
        error_message = f"Erro durante a rotação de credenciais: {str(e)}"
        logger.error(error_message)
        
        send_notification(
            error_message,
            subject="ERRO - Falha na Rotação de Credenciais DigitalOcean"
        )
        
        return {
            "statusCode": 500,
            "body": json.dumps({"error": error_message})
        }
EOF
}

# Criar Secret Manager para armazenar os tokens do DigitalOcean
resource "aws_secretsmanager_secret" "digitalocean_tokens" {
  name        = "${var.environment}-${var.project_name}-do-tokens"
  description = "Armazena os tokens da API Digital Ocean para o projeto ${var.project_name}"

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.project_name}-do-tokens"
    Environment = var.environment
    Project     = var.project_name
    Module      = "credential-rotation"
  })
}

# Armazenar o token inicial no Secret Manager
resource "aws_secretsmanager_secret_version" "initial_token" {
  secret_id = aws_secretsmanager_secret.digitalocean_tokens.id
  secret_string = jsonencode({
    digitalocean_token = var.initial_token,
    last_rotated       = timestamp(),
    created_by         = "terraform"
  })

  lifecycle {
    # Evitar atualizações deste recurso após a criação inicial
    ignore_changes = [secret_string]
  }
}

# Definir IAM Role para a função Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${local.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name        = "${local.function_name}-role"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Política para acessar Secret Manager e SNS
resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.function_name}-policy"
  description = "Permite que a função Lambda rotacione credenciais"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret"
        ]
        Resource = aws_secretsmanager_secret.digitalocean_tokens.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn != "" ? var.sns_topic_arn : "*"
      }
    ]
  })
}

# Anexar política à role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Criar função Lambda para rotação de credenciais
resource "aws_lambda_function" "credential_rotation" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  memory_size   = 128

  # Código da função inline usando arquivo zip
  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  environment {
    variables = {
      SECRET_NAME   = aws_secretsmanager_secret.digitalocean_tokens.name
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  tags = merge(var.tags, {
    Name        = local.function_name
    Environment = var.environment
    Project     = var.project_name
    Module      = "credential-rotation"
  })
}

# Criar arquivo zip com o código da função Lambda
data "archive_file" "lambda_code" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<EOF
${local.lambda_function_code}
EOF
    filename = "index.py"
  }
}

# Criar regra EventBridge para acionar a função periodicamente
resource "aws_cloudwatch_event_rule" "rotation_schedule" {
  name                = "${local.function_name}-schedule"
  description         = "Agenda para rotação automática de credenciais"
  schedule_expression = local.schedule_expression

  tags = merge(var.tags, {
    Name        = "${local.function_name}-schedule"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Definir o alvo da regra como a função Lambda
resource "aws_cloudwatch_event_target" "rotation_target" {
  rule      = aws_cloudwatch_event_rule.rotation_schedule.name
  target_id = "InvokeCredentialRotation"
  arn       = aws_lambda_function.credential_rotation.arn
}

# Permitir que o EventBridge invoque a função Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.credential_rotation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotation_schedule.arn
}

# CloudWatch Alarm para monitorar falhas na rotação de credenciais
resource "aws_cloudwatch_metric_alarm" "rotation_errors" {
  alarm_name          = "${local.function_name}-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Monitora erros na função de rotação de credenciais"

  dimensions = {
    FunctionName = aws_lambda_function.credential_rotation.function_name
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = merge(var.tags, {
    Name        = "${local.function_name}-error-alarm"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Registro de quando a última rotação ocorreu (para referência)
resource "aws_ssm_parameter" "last_rotation" {
  name        = "/${var.environment}/${var.project_name}/credentials/last-rotation"
  description = "Registro da última rotação de credenciais"
  type        = "String"
  value       = timestamp()

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.project_name}-last-rotation"
    Environment = var.environment
    Project     = var.project_name
  })
}

