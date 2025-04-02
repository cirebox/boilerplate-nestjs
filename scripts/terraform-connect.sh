#!/bin/bash
# Script para conectar a aplicação NestJS à infraestrutura criada pelo Terraform

# Certifique-se de estar no diretório correto
cd "$(dirname "$0")/.."


# Verifica se o Terraform foi executado com sucesso
if [ ! -f "./terraform/plan.tfplan" ]; then
  echo "❌ Plano do Terraform não encontrado. Execute terraform plan primeiro."
  exit 1
fi

echo "🔍 Obtendo informações da infraestrutura Terraform..."

# Definir o diretório do Terraform
TERRAFORM_DIR="./terraform"
ENV=${1:-"dev"}

# Extrair endpoints e dados sensíveis do Terraform (em produção usaria variáveis de saída do Terraform)
cd $TERRAFORM_DIR

# Simula a obtenção dos outputs do Terraform
echo "📊 Obtendo outputs do Terraform..."
# Em um cenário real, você executaria:
# DB_ENDPOINT=$(terraform output -raw database_endpoint)
# DB_PASSWORD=$(terraform output -raw database_password)
# K8S_ENDPOINT=$(terraform output -raw kubernetes_endpoint)

# Para este exemplo, como estamos apenas testando, usaremos valores simulados
DB_ENDPOINT="boilerplate-nestjs-dev-db.internal:5432"
DB_PASSWORD="example_secure_password"
DB_USER="app_user"
DB_NAME="boilerplate_nestjs_dev"
K8S_ENDPOINT="https://boilerplate-nestjs-dev-k8s.internal:6443"

echo "💾 Criando arquivo .env.terraform..."
cd ..

# Criar arquivo .env.terraform com as configurações reais
cat > .env.terraform << EOF2
# Arquivo gerado automaticamente pelo script terraform-connect.sh
# Criado em: $(date)

# Conexão com o banco de dados PostgreSQL provisionado pelo Terraform
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@${DB_ENDPOINT}/${DB_NAME}

# Outras configurações da aplicação
NODE_ENV=${ENV}
HTTP_PORT=3000
JWT_SECRET_KEY=terraform-generated-secret-key

# Configurações de monitoramento
EXTERNAL_API_URL=https://api-${ENV}.example.com/health

# Nota: Em um ambiente real, mais configurações seriam adicionadas aqui
EOF2

echo "✅ Configuração concluída! Arquivo .env.terraform criado com sucesso."
echo "⚙️  Para usar estas configurações, execute: cp .env.terraform .env"
echo "🚀 Para gerar a migração do Prisma com estas configurações, execute: npx prisma migrate dev"

# Verificar se o banco de dados está acessível (simulado para este exemplo)
echo "🔄 Verificando conexão com o banco de dados..."
echo "  ⚠️ Conexão simulada para fins de teste. Em um ambiente real, testaria o acesso ao banco de dados."

# Em um cenário real, você verificaria a conexão com:
# DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_ENDPOINT}/${DB_NAME}" npx prisma db push --skip-generate

echo "📝 Resumo da infraestrutura:"
echo "  📊 Banco de dados: ${DB_ENDPOINT}"
echo "  📊 Kubernetes: ${K8S_ENDPOINT}"
echo "  📊 Ambiente: ${ENV}"
