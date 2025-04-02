# Módulo Terraform para Ambiente Local

Este módulo permite a criação de um ambiente de desenvolvimento local utilizando Docker, facilitando o desenvolvimento e testes da aplicação NestJS sem a necessidade de uma infraestrutura de nuvem.

## Recursos Criados

- **Rede Docker**: Uma rede isolada para comunicação entre os serviços
- **Volume de Dados**: Volume persistente para armazenamento de dados do PostgreSQL
- **Contêiner PostgreSQL**: Banco de dados para a aplicação
- **Contêiner da Aplicação** (opcional): Execução da aplicação NestJS

## Requisitos

- Docker instalado e em execução no host local
- Terraform versão 1.0.0 ou superior
- Imagem do aplicativo NestJS disponível (se `deploy_app = true`)

## Uso

```hcl
module "local_environment" {
  source = "./modules/local"
  
  project_name     = "nestjs-boilerplate"
  docker_host      = "unix:///var/run/docker.sock"
  network_name     = "nestjs-network"
  data_volume_name = "nestjs-data"
  db_username      = "postgres"
  db_password      = "postgres"
  db_name          = "nestjs"
  db_port          = 5432
  app_port         = 3000
  app_image        = "node:18-alpine"  # ou uma imagem personalizada da sua aplicação
  database_image   = "postgres:14"
  deploy_app       = true  # definir como false se quiser apenas o banco de dados
}
```

## Integração com o Ambiente de Configuração

Para utilizar este módulo com a configuração de ambientes, configure o arquivo `config.yaml` do ambiente desejado para usar o provedor local:

```yaml
provider:
  active: "local"
  local:
    docker_host: "unix:///var/run/docker.sock"
    deploy_app: true
    # Outras configurações...
```

Em seguida, execute o Terraform no diretório principal:

```bash
terraform init
terraform apply -var environment=dev -var active_provider=local
```

## Variáveis de Entrada

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|:--------:|
| project_name | Nome do projeto que será usado como prefixo | `string` | - | sim |
| docker_host | URL do host Docker (ex: unix:///var/run/docker.sock) | `string` | `"unix:///var/run/docker.sock"` | não |
| network_name | Nome da rede Docker | `string` | - | sim |
| data_volume_name | Nome do volume de dados | `string` | - | sim |
| db_username | Nome de usuário do PostgreSQL | `string` | - | sim |
| db_password | Senha do PostgreSQL | `string` | - | sim |
| db_name | Nome do banco de dados | `string` | - | sim |
| db_port | Porta mapeada para o PostgreSQL | `number` | `5432` | não |
| app_port | Porta mapeada para a aplicação | `number` | `3000` | não |
| app_image | Imagem Docker para a aplicação | `string` | `"node:18-alpine"` | não |
| database_image | Imagem Docker para o PostgreSQL | `string` | `"postgres:14"` | não |
| deploy_app | Se true, implanta o contêiner da aplicação | `bool` | `true` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| database_container_name | Nome do contêiner do banco de dados |
| database_container_ip | Endereço IP interno do contêiner do banco de dados |
| app_container_name | Nome do contêiner da aplicação (se deploy_app = true) |
| app_container_ip | Endereço IP interno do contêiner da aplicação (se deploy_app = true) |
| app_url | URL para acessar a aplicação (se deploy_app = true) |
| network_id | ID da rede Docker criada |

## Testes

O módulo inclui testes automatizados usando o framework Terratest. Para executar os testes:

```bash
cd terraform/tests
go test -v -run TestLocal*
```

## Limitações

- Este módulo é destinado apenas para ambientes de desenvolvimento e testes
- Não deve ser utilizado para produção
- As credenciais do banco de dados são armazenadas em texto plano no state do Terraform

## Exemplos Adicionais

### Usando com Kind (Kubernetes in Docker)

Para criar um ambiente local com Kubernetes usando Kind, ajuste a configuração:

```yaml
provider:
  active: "local"
  local:
    docker_host: "unix:///var/run/docker.sock"
    deploy_app: false  # A aplicação será implantada via Kubernetes
    
kubernetes:
  local:
    enable_kind: true
    kind_cluster_name: "nestjs-dev"
    kind_config_path: "./kind-config.yaml"
```

### Usando com Docker Compose

Este módulo pode ser usado em conjunto com Docker Compose para serviços adicionais. Crie um arquivo `docker-compose.override.yml` na raiz do projeto para adicionar serviços complementares.