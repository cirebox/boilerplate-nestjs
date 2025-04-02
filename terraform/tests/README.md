# Testes Automatizados para Infraestrutura Terraform

Este diretório contém testes automatizados para validar a infraestrutura Terraform do projeto. Os testes utilizam [Terratest](https://terratest.gruntwork.io/), uma biblioteca em Go para testar infraestrutura como código.

## Pré-requisitos

Para executar os testes automatizados, você precisará das seguintes ferramentas instaladas:

- [Go](https://golang.org/doc/install) (versão 1.16 ou superior)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) (versão 1.0.0 ou superior)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) (para testes da AWS)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (para testes do GCP)
- [DigitalOcean CLI (doctl)](https://docs.digitalocean.com/reference/doctl/how-to/install/) (para testes do DigitalOcean)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (para testes do Azure, se implementados)

## Estrutura de Diretórios

```
tests/
├── aws/            # Testes específicos para AWS
├── gcp/            # Testes específicos para GCP
├── digital-ocean/  # Testes específicos para DigitalOcean
├── fixtures/       # Configurações Terraform usadas pelos testes
└── common/         # Funções auxiliares compartilhadas entre os testes
```

## Configuração de Credenciais

### AWS

Para executar testes com AWS, configure suas credenciais usando um dos métodos abaixo:

1. Variáveis de ambiente:
```bash
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

2. Arquivo de credenciais AWS:
```bash
aws configure
```

### Google Cloud Platform (GCP)

Para executar testes com GCP, configure suas credenciais usando um dos métodos abaixo:

1. Variáveis de ambiente:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="caminho/para/arquivo-de-chave.json"
export GOOGLE_PROJECT="seu-projeto-gcp"
```

2. Login via gcloud:
```bash
gcloud auth application-default login
gcloud config set project seu-projeto-gcp
```

### DigitalOcean

Para executar testes com DigitalOcean, configure suas credenciais usando um dos métodos abaixo:

1. Variáveis de ambiente:
```bash
export DIGITALOCEAN_TOKEN="seu-token-do"
```

2. Login via doctl:
```bash
doctl auth init
```

### Azure (se implementado)

Para executar testes com Azure, configure suas credenciais usando um dos métodos abaixo:

1. Variáveis de ambiente:
```bash
export ARM_CLIENT_ID="client-id"
export ARM_CLIENT_SECRET="client-secret"
export ARM_SUBSCRIPTION_ID="subscription-id"
export ARM_TENANT_ID="tenant-id"
```

2. Login via Azure CLI:
```bash
az login
```

## Executando os Testes

### Testes Individuais

Para executar um teste específico:

```bash
cd tests
go test -v -timeout 30m ./aws/load_balancing_test.go
```

### Todos os Testes

Para executar todos os testes:

```bash
cd tests
go test -v -timeout 60m ./...
```

### Testes para um Provedor Específico

Para executar todos os testes de um provedor específico:

```bash
cd tests
go test -v -timeout 30m ./digital-ocean/...
```

## Exemplos de Comandos

### Testar módulo de Load Balancing do DigitalOcean

```bash
cd tests
go test -v -timeout 30m ./digital-ocean/load_balancing_test.go
```

### Testar módulo de banco de dados do AWS

```bash
cd tests
go test -v -timeout 30m ./aws/database_test.go
```

### Testar módulo de Kubernetes do GCP

```bash
cd tests
go test -v -timeout 30m ./gcp/kubernetes_test.go
```

## Variáveis de Configuração

Você pode personalizar os testes usando variáveis de ambiente:

```bash
# Para pular limpeza após testes (útil para depuração)
export SKIP_TEARDOWN=true

# Para definir um prefixo para recursos
export TEST_RESOURCE_PREFIX="test-prefix"

# Para usar uma região específica
export AWS_REGION="us-west-2"
export DIGITALOCEAN_REGION="nyc3"
export GCP_REGION="us-central1"
```

## Adicionando Novos Testes

1. Crie um novo arquivo de teste Go no diretório apropriado
2. Siga o padrão de testes existentes
3. Adicione configurações necessárias no diretório `fixtures/`
4. Execute o teste individualmente para verificar se está funcionando

## Solução de Problemas

### Erros de Credenciais

Se encontrar erros relacionados a credenciais, verifique:
- Se as variáveis de ambiente estão definidas corretamente
- Se você tem permissões suficientes na sua conta de nuvem
- Se os tokens não estão expirados

### Timeouts

Os testes de infraestrutura podem levar tempo. Se encontrar timeouts:
- Aumente o valor do parâmetro `-timeout` (ex: `-timeout 60m`)
- Verifique se há limites de recursos na sua conta de nuvem

### Recursos não sendo destruídos

Se os recursos não forem limpos após os testes:
- Verifique se `SKIP_TEARDOWN` não está definido como `true`
- Verifique se há erros durante a fase de limpeza nos logs
- Limpe manualmente os recursos com o prefixo de teste

