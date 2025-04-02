# Módulo de Load Balancing

## Visão Geral

Este módulo fornece uma interface unificada para implementar balanceadores de carga em diferentes provedores de nuvem. Ele abstrai as complexidades específicas de cada provedor, permitindo uma configuração consistente independentemente da infraestrutura subjacente.

## Características Principais

- Interface uniforme para diferentes provedores de nuvem
- Suporte para balanceamento de carga HTTP/HTTPS
- Configuração de health checks
- Regras de firewall automáticas
- Suporte para TLS/SSL
- Escalabilidade automática (dependendo do provedor)

## Provedores Suportados

Atualmente, o módulo suporta os seguintes provedores de nuvem:

- Digital Ocean
- AWS (Amazon Web Services)
- GCP (Google Cloud Platform)

## Pré-requisitos

Para usar este módulo, você precisa:

1. Ter o Terraform v1.0.0 ou superior instalado
2. Ter configurado as credenciais do provedor escolhido
3. Ter uma VPC/rede já configurada
4. Ter os serviços de destino (backends) já configurados

## Como Usar

Para usar este módulo, inclua-o no seu código Terraform conforme mostrado abaixo:

```hcl
module "load_balancer" {
  source = "path/to/modules/load_balancing/main"

  # Configurações gerais
  name        = "app-lb"
  provider_id = "digital-ocean"  # Opções: "digital-ocean", "aws", "gcp"
  
  # Outras configurações gerais (aplicáveis a todos os provedores)
  region            = "nyc1"
  environment       = "production"
  enable_https      = true
  forwarding_rules  = var.forwarding_rules
  health_check      = var.health_check
  target_tags       = ["web-servers"]
  
  # Configurações específicas do provedor (serão ignoradas se não forem relevantes para o provedor escolhido)
  do_droplet_ids    = var.do_droplet_ids
  aws_vpc_id        = var.aws_vpc_id
  aws_subnet_ids    = var.aws_subnet_ids
  gcp_network_name  = var.gcp_network_name
  
  # Tags para gerenciamento de recursos
  tags = {
    "Environment" = "Production"
    "Project"     = "MyApp"
    "ManagedBy"   = "Terraform"
  }
}
```

## Exemplos de Uso por Provedor

### Digital Ocean

```hcl
module "do_load_balancer" {
  source = "path/to/modules/load_balancing/main"

  name        = "web-lb"
  provider_id = "digital-ocean"
  region      = "nyc1"
  
  forwarding_rules = [
    {
      entry_port      = 80
      entry_protocol  = "http"
      target_port     = 8080
      target_protocol = "http"
    },
    {
      entry_port      = 443
      entry_protocol  = "https"
      target_port     = 8080
      target_protocol = "http"
      certificate_id  = "your-certificate-id"
    }
  ]
  
  health_check = {
    protocol               = "http"
    port                   = 8080
    path                   = "/health"
    check_interval_seconds = 10
    timeout_seconds        = 5
    healthy_threshold      = 3
    unhealthy_threshold    = 2
  }
  
  do_droplet_ids = [
    "droplet-id-1", 
    "droplet-id-2"
  ]
  
  enable_proxy_protocol = false
  enable_backend_keepalive = true
  
  tags = {
    "Environment" = "Production"
    "Service"     = "WebApp"
  }
}
```

### AWS

```hcl
module "aws_load_balancer" {
  source = "path/to/modules/load_balancing/main"

  name        = "api-lb"
  provider_id = "aws"
  region      = "us-east-1"
  
  forwarding_rules = [
    {
      entry_port      = 80
      entry_protocol  = "HTTP"
      target_port     = 8080
      target_protocol = "HTTP"
    },
    {
      entry_port      = 443
      entry_protocol  = "HTTPS"
      target_port     = 8080
      target_protocol = "HTTP"
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-ef56-gh78-ij90-klmn1234pqrs"
    }
  ]
  
  health_check = {
    protocol               = "HTTP"
    port                   = 8080
    path                   = "/api/health"
    interval_seconds       = 30
    timeout_seconds        = 5
    healthy_threshold      = 2
    unhealthy_threshold    = 3
    matcher                = "200-299"
  }
  
  aws_vpc_id     = "vpc-12345678"
  aws_subnet_ids = ["subnet-abc123", "subnet-def456", "subnet-ghi789"]
  
  access_logs = {
    bucket  = "lb-logs-bucket"
    prefix  = "api-lb"
    enabled = true
  }
  
  tags = {
    "Environment" = "Staging"
    "Service"     = "API"
  }
}
```

### GCP

```hcl
module "gcp_load_balancer" {
  source = "path/to/modules/load_balancing/main"

  name        = "app-lb"
  provider_id = "gcp"
  region      = "us-central1"
  
  forwarding_rules = [
    {
      entry_port      = 80
      entry_protocol  = "HTTP"
      target_port     = 8080
      target_protocol = "HTTP"
    },
    {
      entry_port      = 443
      entry_protocol  = "HTTPS"
      target_port     = 8080
      target_protocol = "HTTP"
      certificate_id  = "projects/my-project/global/sslCertificates/my-cert"
    }
  ]
  
  health_check = {
    protocol               = "HTTP"
    port                   = 8080
    path                   = "/healthz"
    check_interval_seconds = 15
    timeout_seconds        = 5
    healthy_threshold      = 2
    unhealthy_threshold    = 3
  }
  
  gcp_network_name = "default"
  
  tags = {
    "environment" = "production"
    "application" = "frontend"
  }
}
```

## Entradas do Módulo

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|------------|
| name | Nome do balanceador de carga | string | - | sim |
| provider_id | ID do provedor (digital-ocean, aws, gcp) | string | - | sim |
| region | Região onde o balanceador de carga será implantado | string | - | sim |
| forwarding_rules | Lista de regras de encaminhamento | list(object) | [] | sim |
| health_check | Configuração do health check | object | {} | sim |
| enable_https | Habilitar suporte HTTPS | bool | false | não |
| tags | Tags para o balanceador de carga | map(string) | {} | não |

Para uma lista completa de variáveis, consulte o arquivo `variables.tf`.

## Saídas do Módulo

| Nome | Descrição |
|------|-----------|
| load_balancer_id | ID do balanceador de carga |
| load_balancer_ip | Endereço IP do balanceador de carga |
| load_balancer_hostname | Nome de host do balanceador de carga |
| load_balancer_status | Status atual do balanceador de carga |

## Melhores Práticas

1. **Segurança**: Sempre habilite HTTPS para aplicações em produção
2. **Health Checks**: Configure health checks adequados para seus serviços
3. **Logs**: Habilite logs para diagnóstico e auditoria
4. **Monitoramento**: Integre com o sistema de monitoramento da sua infraestrutura
5. **Backup**: Mantenha configurações de backup para recuperação rápida

## Solução de Problemas

### Problemas Comuns

- **Falha na criação**: Verifique as permissões e cotas do provedor
- **Health checks falhando**: Verifique se a rota de health check está respondendo corretamente
- **Certificados SSL/TLS**: Certifique-se de que os certificados são válidos e estão configurados corretamente

### Logs para Diagnóstico

Todos os provedores oferecem logs detalhados para diagnóstico:

- **Digital Ocean**: Console do DO > Networking > Load Balancers > seu-lb > Metrics
- **AWS**: CloudWatch Logs, se configurado com access_logs
- **GCP**: Stackdriver Logging

## Como Contribuir

Contribuições para este módulo são bem-vindas! Para contribuir:

1. Faça um fork do repositório
2. Crie um branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Implemente suas mudanças
4. Adicione testes para suas mudanças
5. Envie um pull request

### Diretrizes para Contribuição

- Mantenha a compatibilidade com versões anteriores sempre que possível
- Documente todas as variáveis e saídas
- Forneça exemplos para novos recursos
- Siga as práticas recomendadas do Terraform
- Garanta que todas as implementações de provedores tenham funcionalidades equivalentes

## Licença

Este módulo é distribuído sob a licença MIT.

