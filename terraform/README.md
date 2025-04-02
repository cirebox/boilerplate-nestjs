# Infraestrutura como Código - Terraform

Este diretório contém a configuração de infraestrutura como código (IaC) para o projeto boilerplate-nestjs, permitindo o provisionamento da infraestrutura de forma automatizada e repetível em múltiplos provedores de nuvem.

## Visão Geral

A infraestrutura deste projeto foi projetada para ser multi-cloud, suportando ambientes em:

- **AWS** (Amazon Web Services)
- **GCP** (Google Cloud Platform)
- **DigitalOcean** (Provedor padrão atual)
- **Local** (Ambiente de desenvolvimento usando Docker)

### Diagrama da Arquitetura

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

## Design Técnico

### Principais Princípios

1. **Abordagem Multi-cloud**:

    - Abstração de provedores específicos através de módulos
    - Configurações específicas isoladas por provedor
    - Fácil migração entre provedores

2. **Modularização**:

    - Módulos reutilizáveis para cada componente de infraestrutura
    - Separação clara entre recursos de rede, banco de dados, Kubernetes, etc.
    - Interfaces consistentes entre módulos

3. **Segurança e Controle de Custos**:
    - Implementação de alertas de custos e limites orçamentários
    - Rotação automática de credenciais
    - Monitoramento proativo
    - Otimização baseada em ambientes (dev/staging/prod)

## Estrutura de Arquivos

```
terraform/
├── .pre-commit-config.yaml       # Configurações de hooks pre-commit
├── .gitignore                    # Arquivos ignorados pelo git
├── main.tf                       # Configuração principal Terraform
├── variables.tf                  # Variáveis globais
├── outputs.tf                    # Outputs gerais
├── providers.tf                  # Configuração de provedores
├── provider_overrides.tf         # Correções para problemas de namespace
├── environments/                 # Configurações por ambiente
│   ├── dev/                      # Ambiente de desenvolvimento
│   │   ├── config.yaml           # Configuração específica
│   │   ├── main.tf               # Recursos do ambiente dev
│   │   ├── aws/                  # Configs AWS para dev
│   │   ├── gcp/                  # Configs GCP para dev
│   │   └── digital-ocean/        # Configs DO para dev
│   ├── staging/                  # Ambiente de homologação
│   └── prod/                     # Ambiente de produção
│       ├── config.yaml           # Configuração para produção
│       └── main.tf               # Recursos do ambiente prod
├── modules/                      # Módulos reutilizáveis
│   ├── network/                  # Recursos de rede
│   │   ├── aws/                  # Implementação para AWS
│   │   ├── gcp/                  # Implementação para GCP
│   │   └── digital-ocean/        # Implementação para DO
│   ├── database/                 # Recursos de banco de dados
│   ├── kubernetes/               # Clusters Kubernetes
│   ├── monitoring/               # Sistemas de monitoramento
│   ├── cost_monitor/             # Monitoramento de custos
│   ├── load_balancing/           # Balanceadores de carga
│   ├── security/                 # Recursos de segurança
│   └── local/                    # Ambiente de desenvolvimento local
└── README.md                     # Esta documentação
```

## Anatomia dos Módulos

Cada módulo segue uma estrutura consistente:

```
modules/<tipo_recurso>/<provedor>/
├── main.tf           # Definição principal dos recursos
├── variables.tf      # Variáveis de entrada
├── outputs.tf        # Valores de saída
└── README.md         # (Opcional) Documentação específica
```

## Módulos Principais

### Módulo Network

Responsável por configurar toda a infraestrutura de rede, incluindo:

- VPCs/VNets
- Subnets (públicas e privadas)
- NAT Gateways
- Firewall/Security Groups
- DNS (quando aplicável)

### Módulo Database

Configura bancos de dados gerenciados otimizados para:

- Alta disponibilidade (em produção)
- Backup automático
- Segurança
- Controle de custos em ambientes não-produtivos

### Módulo Kubernetes

Provisiona clusters Kubernetes para hospedagem de aplicações:

- Auto-scaling de nós
- Configurações adequadas ao ambiente (prod/staging/dev)
- Integrações com sistemas de monitoramento
- Otimização de custos (uso de instâncias spot em dev/staging)

### Módulo Cost Monitor

Implementa:

- Alertas de orçamento
- Detecção de recursos subutilizados
- Recomendações de otimização
- Relatórios de custo

### Módulo Monitoring

Configura monitoramento para:

- Métricas de recursos (CPU, memória, etc.)
- Logs da aplicação
- Alertas para condições anômalas
- Dashboards com visão geral da infra

### Módulo Local

Permite desenvolvimento local usando:

- Docker para containers
- Volumes persistentes para dados
- Network isolada
- Configuração simplificada

## Sistema de Configuração

### Arquivos de Configuração

Os ambientes são configurados através de arquivos YAML em `environments/<ambiente>/config.yaml`. Exemplo:

```yaml
provider:
    active: 'digitalocean' # Provedor ativo

    digitalocean:
        token_file: '~/.digitalocean/token'
        region: 'nyc1'

    aws:
        profile: 'default'
        region: 'us-east-1'

    gcp:
        project: 'meu-projeto'
        region: 'us-central1'

    local:
        docker_host: 'unix:///var/run/docker.sock'

network:
    vpc_cidr: '10.0.0.0/16'

database:
    engine: 'postgres'
    version: '14'

kubernetes:
    version: '1.26'
    node_instance_types: ['s-2vcpu-2gb']
```

### Variáveis de Ambiente

O projeto permite configuração via variáveis de ambiente, que têm precedência sobre os arquivos de configuração:

```bash
# Token da API (Digital Ocean)
export DIGITALOCEAN_TOKEN="seu_token"

# Credenciais AWS
export AWS_ACCESS_KEY_ID="seu_access_key"
export AWS_SECRET_ACCESS_KEY="seu_secret_key"
export AWS_REGION="us-east-1"

# Credenciais GCP
export GOOGLE_APPLICATION_CREDENTIALS="/caminho/para/credentials.json"
export GOOGLE_PROJECT="seu-projeto-gcp"

# Configurações de alerta
export ALERT_EMAIL="seu_email@exemplo.com"
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"
```

## Estratégia Multi-cloud

A infraestrutura suporta múltiplos provedores através de uma arquitetura modular:

1. **Camada de Abstração**: Define interfaces comuns para todos os provedores
2. **Implementações Específicas**: Cada provedor tem sua implementação
3. **Seleção Dinâmica**: O provedor ativo é selecionado via configuração

Para alternar entre provedores:

```bash
# Usando Digital Ocean
terraform apply -var="environment=prod"

# Alternativamente, edite o arquivo config.yaml:
# provider:
#   active: "aws"  # Mudar para aws, gcp, ou digitalocean
```

## Otimização de Custos

O projeto implementa várias estratégias de otimização:

1. **Ambientes Diferenciados**:

    - **Dev**: Recursos mínimos, auto-desligamento
    - **Staging**: Recursos moderados, auto-scaling
    - **Prod**: Alta disponibilidade, proteção contra exclusão

2. **Monitoramento de Custos**:

    - Alertas de orçamento
    - Detecção de anomalias
    - Relatórios periódicos

3. **Reservas e Spots**:

    - Instâncias spot para ambientes não-produtivos
    - Reservas para workloads estáveis em produção

4. **Auto-scaling**:
    - Escala baseada em demanda
    - Escala para zero em períodos ociosos (dev/staging)

## Segurança

### Principais Medidas de Segurança

1. **Segredos e Tokens**:

    - Armazenados em Secret Manager/Vault
    - Rotação automática de credenciais
    - Nunca comprometidos no código-fonte

2. **Rede**:

    - Recursos críticos em subnets privadas
    - Acessos restritos por CIDR/Security Groups
    - Exposto apenas o necessário

3. **Acesso**:

    - Menor privilégio possível
    - 2FA para acessos administrativos
    - Logs de auditoria

4. **Conformidade**:
    - Validação com ferramentas como:
        - TFLint
        - Terrascan
        - Checkov
        - TFSec

### Rotação de Credenciais

O módulo `security/credential_rotation` implementa rotação automática de tokens:

1. Cria novos tokens periodicamente
2. Atualiza as referências
3. Revoga tokens antigos
4. Notifica administradores

## Implementação por Ambientes

### Ambiente de Desenvolvimento (dev)

- **Objetivos**: Custo mínimo, facilidade de uso
- **Características**:
    - Recursos mínimos (menor tamanho de instâncias)
    - Único nó Kubernetes
    - Sem redundância
    - Sem backups automáticos
    - Possibilidade de auto-desligamento

### Ambiente de Homologação (staging)

- **Objetivos**: Similar à produção, custos controlados
- **Características**:
    - Configuração similar à produção
    - Escalabilidade reduzida
    - Backups menos frequentes
    - Auto-scaling limitado

### Ambiente de Produção (prod)

- **Objetivos**: Confiabilidade, segurança, disponibilidade
- **Características**:
    - Multi-AZ/região
    - Auto-scaling completo
    - Backups frequentes
    - Monitoramento avançado
    - Proteção contra exclusão acidental

## Processo de CI/CD

O projeto utiliza GitHub Actions para automação, com pipelines que:

1. **Validam** o código Terraform
2. **Planejam** as mudanças de infraestrutura
3. **Aplicam** as mudanças aprovadas
4. **Validam** a infraestrutura pós-deploy

Fluxo completo:

```
Commit → Validação → Plano → Aprovação Manual → Apply → Testes
```

## Hooks de Pre-Commit

O projeto utiliza hooks de pre-commit para manter qualidade do código:

- **terraform_fmt**: Formata código Terraform
- **terraform_validate**: Valida a sintaxe
- **terraform_docs**: Atualiza documentação automática
- **terraform_tflint**: Executa linter customizado
- **terrascan**: Verifica conformidade de segurança
- **terraform_tfsec**: Análise de segurança estática
- **terraform_checkov**: Analisa conformidade com políticas
- **shellcheck**: Valida scripts shell
- **gitleaks**: Detecta senhas e tokens expostos
- **typos**: Verifica erros ortográficos
- **commitizen**: Valida formato dos commits
- **markdownlint**: Verifica arquivos Markdown
- **infracost**: Análise de custos

## Uso

### Pré-requisitos

- Terraform v1.0.0+
- Credenciais configuradas para o(s) provedor(es) desejado(s)
- Variáveis de ambiente configuradas conforme necessário

### Configuração Inicial

1. Configure as variáveis de ambiente necessárias
2. Escolha o ambiente e provedor desejados
3. Inicialize o Terraform:

```bash
terraform init
```

### Aplicando Alterações

Visualize as mudanças:

```bash
terraform plan -var="environment=dev" -out=plan.tfplan
```

Aplique as mudanças:

```bash
terraform apply plan.tfplan
```

### Destruindo Recursos

Para ambientes temporários:

```bash
terraform destroy -var="environment=dev"
```

### Trabalhando com Workspaces

Para gerenciar múltiplos estados:

```bash
# Criar workspace para cada ambiente
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Selecionar workspace
terraform workspace select dev

# Aplicar no workspace atual
terraform apply -var="environment=${terraform.workspace}"
```

## Monitoramento e Operação

### Dashboards

O módulo `monitoring` configura dashboards para:

- Métricas de recursos (CPU, memória, disco)
- Utilização de Kubernetes
- Performance de banco de dados
- Custos por serviço/recurso

### Alertas

Configurados alertas para:

- Alta utilização de recursos
- Falhas de saúde em serviços
- Estouros de orçamento
- Falhas em backups

### Recuperação de Desastres

Implementada estratégia de DR que inclui:

- Backups automáticos
- Retenção configurável
- Restauração testada e documentada
- Procedimentos para failover

## Best Practices Implementadas

1. **Modularização**:

    - Componentes isolados e reutilizáveis
    - Interfaces consistentes

2. **Nomeação Consistente**:

    - Convenção clara para todos os recursos
    - Prefixos por ambiente/projeto

3. **Tagging**:

    - Todos os recursos recebem tags para:
        - Ambiente
        - Projeto
        - Gerenciado por (Terraform)
        - Data de criação

4. **Variáveis Padronizadas**:

    - Interface comum entre módulos
    - Defaults razoáveis

5. **Validações**:
    - Validação de inputs
    - Testes automatizados
    - Linting e formatação

## Limitações Conhecidas

1. **Migração Entre Provedores**:

    - Requer planejamento para migração de dados
    - Pode exigir downtime em alguns casos

2. **Estado do Terraform**:

    - Armazenado em backend S3/Spaces
    - Potencial bloqueio de estado em equipes grandes

3. **Recursos Específicos de Provedores**:
    - Alguns recursos não têm equivalentes entre provedores
    - Pode exigir ajustes para recursos específicos

## Futuras Melhorias

1. **Automatização Adicional**:

    - Backup/restore automatizado
    - Rollbacks automáticos
    - Validação pós-deploy mais abrangente

2. **Observabilidade**:

    - Integração com sistemas de APM
    - Tracing distribuído
    - Logs centralizados

3. **Segurança**:

    - Escaneamento contínuo de vulnerabilidades
    - Políticas de Kubernetes mais restritivas
    - Integração com ferramentas SAST/DAST

4. **Otimização**:
    - Rightsizing automático baseado em telemetria
    - Hibernação programada para ambientes não-produtivos
    - Reservas automáticas baseadas em uso histórico

## Solução de Problemas Comuns

### Backend S3 não inicializa

Se você encontrar erros com o backend S3:

1. Verifique se o bucket existe
2. Confirme que suas credenciais têm acesso
3. Verifique se a região está correta

```bash
# Verificar se o bucket existe
aws s3 ls s3://terraform-state-boilerplate-nestjs

# Criar o bucket se não existir
aws s3 mb s3://terraform-state-boilerplate-nestjs --region us-east-1
```

### Erros de token expirado

Se receber erros de autenticação:

1. Verifique se o token é válido
2. Confirme que o token tem permissões suficientes
3. Renove o token conforme necessário

### Conflitos de estado

Se múltiplas pessoas estão trabalhando:

1. Use o backend remoto com bloqueio de estado
2. Divida estados por ambiente/componente
3. Comunique-se antes de alterações grandes

## Contribuição

Para contribuir com o código de infraestrutura:

1. Faça fork do repositório
2. Crie um branch para sua feature
3. Implemente suas alterações seguindo as convenções
4. Execute os hooks de pré-commit
5. Abra um PR com descrição detalhada

## Contato e Suporte

Para questões relacionadas à infraestrutura, entre em contato com a equipe DevOps.

## Licença

Este código de infraestrutura é distribuído sob a mesma licença do projeto principal.

## Histórico de Atualizações

| Data       | Versão | Descrição das Alterações              |
| ---------- | ------ | ------------------------------------- |
| 2023-12-01 | 1.0    | Configuração inicial                  |
| 2024-06-01 | 1.1    | Melhorias na documentação e segurança |
