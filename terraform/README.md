# Infraestrutura como Código - Terraform

Este diretório contém a configuração de infraestrutura como código (IaC) para o projeto boilerplate-nestjs, permitindo o provisionamento da infraestrutura de forma automatizada e repetível.

## Arquitetura

A arquitetura de infraestrutura deste projeto é multi-cloud e suporta os seguintes provedores:
- **AWS** (Amazon Web Services)
- **GCP** (Google Cloud Platform) 
- **DigitalOcean** (Provedor padrão atual)

### Visão Geral da Arquitetura

```
                       ┌─────────────────┐
                       │   API Gateway   │
                       └────────┬────────┘
                                │
                                ▼
┌────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Monitoring   │◄────┤  Kubernetes     │────►│  Cost Monitor   │
│  (Prometheus)  │     │  Cluster        │     │   & Alerts      │
└────────────────┘     └────────┬────────┘     └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Database      │
                       │  (PostgreSQL)   │
                       └─────────────────┘
```

### Escolhas de Design

1. **Abordagem Multi-cloud**: 
   - A infraestrutura foi projetada para funcionar em múltiplos provedores de nuvem para evitar dependência de um único fornecedor
   - Cada provedor tem implementações específicas dos mesmos recursos, permitindo migração com interrupção mínima

2. **Modularização**:
   - Separação clara entre recursos compartilhados (rede, banco de dados, monitoramento)
   - Módulos independentes para facilitar a manutenção e evolução da infraestrutura

3. **Foco em Segurança e Custo**:
   - Implementação de alertas de custos e limites orçamentários
   - Isolamento de rede com acessos restritos
   - Backup automático de dados críticos

## Estrutura de Diretórios

```
terraform/
├── aws/                  # Configurações específicas da AWS
├── digital-ocean/        # Configurações específicas do DigitalOcean
├── environments/         # Configurações específicas de ambiente
│   ├── dev/              # Ambiente de desenvolvimento
│   ├── prod/             # Ambiente de produção
│   └── staging/          # Ambiente de staging
├── gcp/                  # Configurações específicas do Google Cloud
├── modules/              # Módulos reutilizáveis de Terraform
│   ├── cost_monitor/     # Monitoramento e alertas de custos
│   ├── database/         # Bancos de dados gerenciados
│   ├── kubernetes/       # Clusters Kubernetes
│   ├── monitoring/       # Monitoramento e alertas
│   └── network/          # Configurações de rede
├── main.tf               # Configuração principal
├── variables.tf          # Definição de variáveis
└── README.md             # Esta documentação
```

## Módulos

### Módulo Network

**Propósito**: Configurar redes privadas, subnets e gateways necessários para garantir o isolamento de recursos e a segurança.

**Implementações**:
- `network/aws`: VPC, subnets públicas/privadas, NAT Gateway, Internet Gateway
- `network/gcp`: VPC, subnet, Cloud Router, Cloud NAT
- `network/digital-ocean`: VPC, Firewall

### Módulo Database

**Propósito**: Provisionar bancos de dados gerenciados otimizados para alta disponibilidade, backup automático e escalabilidade.

**Implementações**:
- `database/aws`: Amazon RDS PostgreSQL com configuração de backup e alta disponibilidade
- `database/gcp`: Cloud SQL PostgreSQL com alta disponibilidade e recuperação point-in-time
- `database/digital-ocean`: DigitalOcean Managed PostgreSQL Database

### Módulo Kubernetes

**Propósito**: Criar e configurar clusters Kubernetes para hospedagem de aplicações em contêineres com auto-scaling.

**Recursos**:
- Proteção contra exclusão acidental em ambiente de produção (`prevent_destroy = true`)
- Auto-scaling de nós baseado em métricas de CPU e memória
- Controle de custo com uso de instâncias spot em ambientes não produtivos

**Implementações**:
- `kubernetes/aws`: Amazon EKS com node groups otimizados
- `kubernetes/gcp`: Google Kubernetes Engine (GKE) com auto-scaling
- `kubernetes/digital-ocean`: DigitalOcean Kubernetes (DOKS)

### Módulo Cost Monitor

**Propósito**: Monitorar, alertar e otimizar custos de infraestrutura em todos os ambientes.

**Implementações**:
- `cost_monitor/aws`: AWS Budgets e Cost Explorer com alertas de limite orçamentário
- `cost_monitor/gcp`: Google Cloud Billing Budgets e recomendações de otimização
- `cost_monitor/digital-ocean`: Alertas de cobrança via API

### Módulo Monitoring

**Propósito**: Configurar monitoramento e alertas para métricas de aplicação e infraestrutura.

**Implementações**:
- `monitoring/aws`: CloudWatch Alarms e Dashboards com integração ao Slack
- `monitoring/gcp`: Cloud Monitoring (Stackdriver) com alertas configuráveis
- `monitoring/digital-ocean`: Monitoramento via Prometheus/Grafana

## Como usar

### Pré-requisitos
- Terraform v1.0.0+
- Credenciais configuradas para o(s) provedor(es) de nuvem desejado(s)
- Variáveis de ambiente configuradas (veja abaixo)

### Variáveis de Ambiente Necessárias

Antes de executar o Terraform, configure as seguintes variáveis de ambiente conforme o provedor escolhido:

**Para Digital Ocean (provedor padrão):**
```bash
# Token de API da Digital Ocean (obrigatório)
export DIGITALOCEAN_TOKEN="seu_token_aqui"

# URL do Webhook do Slack para notificações de alertas (opcional)
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"

# Email para receber alertas (obrigatório)
export ALERT_EMAIL="seu_email@exemplo.com"

# Endpoint para healthcheck da aplicação (obrigatório em produção)
export SERVICE_HEALTH_ENDPOINT="https://api.seu-dominio.com/health"
```

**Para AWS:**
```bash
export AWS_ACCESS_KEY_ID="seu_access_key"
export AWS_SECRET_ACCESS_KEY="seu_secret_key"
export AWS_REGION="us-east-1"
```

**Para GCP:**
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/caminho/para/credentials.json"
export GOOGLE_PROJECT="seu-projeto-gcp"
```

### Configuração Inicial

1. Escolha o ambiente e o provedor em `environments/<ambiente>/config.yaml`
2. Configure as variáveis de ambiente necessárias (veja acima)
3. Inicialize o Terraform:

```bash
terraform init
```

### Planejamento e Aplicação

Revise as mudanças a serem aplicadas:

```bash
terraform plan -out=plan.tfplan
```

Aplique as mudanças:

```bash
terraform apply plan.tfplan
```

### Usando múltiplos provedores

Para alternar entre provedores, modifique o parâmetro `active` no arquivo de configuração do ambiente:

```yaml
provider:
  active: aws  # Alternativas: gcp, digitalocean
  aws:
    region: us-east-1
    profile: default
  # Outras configurações...
```

## Práticas de Segurança

- Backend remoto S3/DynamoDB para armazenamento seguro do estado do Terraform
- Proteção contra exclusão em recursos críticos em produção
- Redes isoladas com acesso controlado
- Credenciais gerenciadas via variáveis de ambiente (recomendado) ou arquivos externos (não versionados)

### Melhores Práticas de Segurança

1. **Nunca comite credenciais ou tokens no repositório**
2. **Ative a autenticação de dois fatores (2FA) para todas as contas de provedores de nuvem**
3. **Use o menor privilégio possível para credenciais de acesso**
4. **Rotacione periodicamente as credenciais e tokens de acesso**

## Monitoramento de Custos

- Alertas via e-mail e Slack quando os custos se aproximam dos limites configurados
- Relatórios semanais de gastos e recomendações de otimização
- Tags automáticas para facilitar o rastreamento de custos por ambiente/projeto

### Limites de Custo Padrão

| Ambiente | Limite Mensal | Alertas em % |
|----------|---------------|--------------|
| dev      | $50 USD       | 50%, 80%, 90% |
| staging  | $100 USD      | 50%, 80%, 90% |
| prod     | $300 USD      | 50%, 70%, 90% |

## Solução de Problemas Comuns

### Backend S3 não inicializa

Se você encontrar erros com o backend S3, verifique:
1. Se o bucket existe e você tem acesso a ele
2. Se as credenciais AWS estão configuradas corretamente
3. Se a região do bucket corresponde à configuração

```bash
# Verificar se o bucket existe
aws s3 ls s3://terraform-state-boilerplate-nestjs

# Criar o bucket se não existir
aws s3 mb s3://terraform-state-boilerplate-nestjs --region us-east-1
```

### Erros de token expirado

Se receber erros de autenticação do provedor, verifique:
1. Se o token configurado é válido
2. Se o token tem as permissões necessárias
3. Se a variável de ambiente está definida corretamente

## Contatos e Suporte

Para dúvidas ou problemas relacionados à infraestrutura, entre em contato com a equipe DevOps.

## Histórico de Atualizações

| Data       | Versão | Descrição das Alterações                 |
|------------|--------|------------------------------------------|
| 2023-12-01 | 1.0    | Configuração inicial                     |
| 2024-06-01 | 1.1    | Melhorias na documentação e segurança    |
