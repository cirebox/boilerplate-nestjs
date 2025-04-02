#!/bin/bash
# Script para executar os testes de conformidade do terraform-compliance
# contra o plano do Terraform para diferentes ambientes.
#
# Uso: ./run_compliance.sh [ambiente] [diretório-features]
#   - ambiente: dev, staging, prod (padrão: dev)
#   - diretório-features: caminho para diretório com features (padrão: ./features)

set -eo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Função para exibir mensagens de erro e sair
function erro() {
    echo -e "${RED}ERRO: $1${NC}" >&2
    exit 1
}

# Função para exibir mensagens de informação
function info() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

# Função para exibir mensagens de sucesso
function sucesso() {
    echo -e "${GREEN}SUCESSO: $1${NC}"
}

# Verificar dependências
command -v terraform >/dev/null 2>&1 || erro "Terraform não está instalado"
command -v terraform-compliance >/dev/null 2>&1 || erro "terraform-compliance não está instalado. Instale com: pip install terraform-compliance"

# Parâmetros padrão
AMBIENTE=${1:-dev}
FEATURES_DIR=${2:-$(dirname "$0")/features}

# Validar parâmetros
if [[ ! "$AMBIENTE" =~ ^(dev|staging|prod)$ ]]; then
    erro "Ambiente inválido. Use dev, staging ou prod."
fi

if [ ! -d "$FEATURES_DIR" ]; then
    erro "Diretório de features não encontrado: $FEATURES_DIR"
fi

# Configurar diretório do ambiente
ENV_DIR="$(pwd)/environments/$AMBIENTE"
if [ ! -d "$ENV_DIR" ]; then
    erro "Diretório do ambiente não encontrado: $ENV_DIR"
fi

# Arquivo temporário para o plano do Terraform
PLAN_FILE="/tmp/terraform_plan_$AMBIENTE.json"

# Diretório atual e validação
CURRENT_DIR=$(pwd)
if [[ "$CURRENT_DIR" != *"/terraform" ]]; then
    info "Diretório atual não é o diretório terraform. Tentando localizar..."
    
    if [ -d "./terraform" ]; then
        cd ./terraform
    elif [[ "$CURRENT_DIR" == *"/terraform/"* ]]; then
        cd "$(echo $CURRENT_DIR | sed 's/\(.*\/terraform\).*/\1/')"
    else
        erro "Não foi possível localizar o diretório terraform. Execute este script a partir do diretório raiz do projeto."
    fi
    
    info "Mudou para o diretório: $(pwd)"
fi

# Iniciar o Terraform e gerar o plano em formato JSON
info "Inicializando o Terraform para o ambiente $AMBIENTE..."
cd "$ENV_DIR"

info "Executando terraform init..."
terraform init -reconfigure || erro "Falha ao inicializar o Terraform"

info "Gerando plano do Terraform em formato JSON..."
terraform plan -out=tfplan || erro "Falha ao gerar o plano do Terraform"
terraform show -json tfplan > "$PLAN_FILE" || erro "Falha ao converter o plano para JSON"

# Executar o terraform-compliance
info "Executando terraform-compliance contra o plano..."
terraform-compliance -p "$PLAN_FILE" -f "$FEATURES_DIR" || {
    COMPLIANCE_EXIT=$?
    if [ $COMPLIANCE_EXIT -eq 1 ]; then
        erro "Os testes de conformidade falharam!"
    else
        erro "Erro ao executar o terraform-compliance (código de saída: $COMPLIANCE_EXIT)"
    fi
}

# Limpar arquivos temporários
info "Limpando arquivos temporários..."
rm -f "$PLAN_FILE" tfplan

sucesso "Testes de conformidade concluídos com sucesso para o ambiente $AMBIENTE"

# Retornar ao diretório original
cd - > /dev/null

exit 0

