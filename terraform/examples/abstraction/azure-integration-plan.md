# Plano de Integração do Azure para o Módulo de Load Balancing

## Visão Geral

Este documento descreve o plano detalhado para adicionar suporte ao Azure como um novo provedor de nuvem ao módulo de load balancing. A implementação seguirá o mesmo padrão de abstração usado para os provedores existentes (Digital Ocean, AWS e GCP), garantindo uma interface consistente e fácil de usar.

## Estrutura de Arquivos

```
modules/
└── load_balancing/
    ├── main/                 # Módulo abstrato (já existente)
    │   ├── main.tf           # Atualizar para incluir suporte ao Azure
    │   ├── variables.tf      # Atualizar para incluir variáveis do Azure
    │   ├── outputs.tf        # Atualizar para mapear outputs do Azure
    │   └── README.md         # Atualizar com exemplos do Azure
    └── azure/                # Nova pasta para implementação do Azure
        ├── main.tf           # Implementação do Azure Load Balancer
        ├── variables.tf      # Variáveis específicas do Azure
        └── outputs.tf        # Outputs específicos do Azure
```

## Recursos do Azure Necessários

1. **Azure Load Balancer**
   - `azurerm_lb` - O balanceador de carga principal
   - `azurerm_lb_backend_address_pool` - Pool de backends
   - `azurerm_lb_probe` - Health checks
   - `azurerm_lb_rule` - Regras de balanceamento

2. **Recursos de Rede Relacionados**
   - `azurerm_public_ip` - IP público para o load balancer
   - `azurerm_network_security_group` - Regras de segurança (opcional)
   - `azurerm_network_security_rule` - Regras de firewall (opcional)

3. **Recursos para SSL/TLS (opcional)**
   - `azurerm_application_gateway` - Para casos que precisam de SSL termination
   - `azurerm_key_vault_certificate` - Para armazenar certificados

## Variáveis Necessárias

### No Módulo Específico do Azure (`azure/variables.tf`)

```hcl
variable "resource_group_name" {
  description = "O nome do grupo de recursos do Azure onde os recursos serão criados"
  type        = string
}

variable "location" {
  description = "A região do Azure onde os recursos serão criados"
  type        = string
}

variable "name" {
  description = "Nome do load balancer"
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde o load balancer será implantado"
  type        = string
}

variable "enable_https" {
  description = "Habilitar suporte a HTTPS"
  type        = bool
  default     = false
}

variable "https_certificate_path" {
  description = "Caminho para o certificado TLS/SSL (quando enable_https = true)"
  type        = string
  default     = ""
}

variable "https_certificate_password" {
  description = "Senha do certificado TLS/SSL (quando enable_https = true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "backend_port" {
  description = "Porta do backend"
  type        = number
  default     = 80
}

variable "frontend_port" {
  description = "Porta do frontend para HTTP"
  type        = number
  default     = 80
}

variable "frontend_https_port" {
  description = "Porta do frontend para HTTPS"
  type        = number
  default     = 443
}

variable "health_check_path" {
  description = "Caminho para health check"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}

variable "sku" {
  description = "SKU do Load Balancer (Basic ou Standard)"
  type        = string
  default     = "Standard"
}

variable "enable_waf" {
  description = "Habilitar Web Application Firewall (requer Application Gateway)"
  type        = bool
  default     = false
}
```

### Atualizações no Módulo Principal (`main/variables.tf`)

Adicionar novo valor para a variável `provider_type`:

```hcl
variable "provider_type" {
  description = "Tipo de provedor de nuvem a ser usado"
  type        = string
  validation {
    condition     = contains(["digitalocean", "aws", "gcp", "azure"], var.provider_type)
    error_message = "O tipo de provedor deve ser 'digitalocean', 'aws', 'gcp' ou 'azure'."
  }
}
```

## Implementação do Módulo Azure (`azure/main.tf`)

```hcl
resource "azurerm_public_ip" "main" {
  name                = "${var.name}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.sku
  tags                = var.tags
}

resource "azurerm_lb" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  frontend_ip_configuration {
    name                 = "FrontendIP"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.name}-backend-pool"
  loadbalancer_id = azurerm_lb.main.id
}

resource "azurerm_lb_probe" "http" {
  name                = "${var.name}-http-probe"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Http"
  port                = var.backend_port
  request_path        = var.health_check_path
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http" {
  name                           = "${var.name}-http-rule"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = var.frontend_port
  backend_port                   = var.backend_port
  frontend_ip_configuration_name = "FrontendIP"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
  probe_id                       = azurerm_lb_probe.http.id
  idle_timeout_in_minutes        = 5
  enable_floating_ip             = false
}

# Configuração condicional para HTTPS
resource "azurerm_application_gateway" "main" {
  count               = var.enable_https ? 1 : 0
  name                = "${var.name}-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = var.enable_waf ? "WAF_v2" : "Standard_v2"
    tier     = var.enable_waf ? "WAF_v2" : "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "http-port"
    port = var.frontend_port
  }

  frontend_port {
    name = "https-port"
    port = var.frontend_https_port
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  # Configurações adicionais para HTTPS seriam implementadas aqui
  # incluindo SSL certificates, backend pools, etc.

  tags = var.tags
}
```

## Outputs do Azure (`azure/outputs.tf`)

```hcl
output "load_balancer_id" {
  description = "ID do Azure Load Balancer"
  value       = azurerm_lb.main.id
}

output "load_balancer_ip" {
  description = "Endereço IP público do load balancer"
  value       = azurerm_public_ip.main.ip_address
}

output "load_balancer_fqdn" {
  description = "FQDN do load balancer, se disponível"
  value       = azurerm_public_ip.main.fqdn
}

output "backend_pool_id" {
  description = "ID do backend pool"
  value       = azurerm_lb_backend_address_pool.main.id
}

output "https_enabled" {
  description = "Indica se HTTPS está habilitado"
  value       = var.enable_https
}

output "application_gateway_id" {
  description = "ID do Application Gateway (se HTTPS estiver habilitado)"
  value       = var.enable_https ? azurerm_application_gateway.main[0].id : null
}
```

## Atualizações no Módulo Principal (`main/main.tf`)

```hcl
module "azure" {
  source = "../azure"
  count  = var.provider_type == "azure" ? 1 : 0

  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_location
  name                     = var.name
  subnet_id                = var.azure_subnet_id
  enable_https             = var.enable_https
  https_certificate_path   = var.https_certificate_path
  https_certificate_password = var.https_certificate_password
  backend_port             = var.backend_port
  frontend_port            = var.http_port
  frontend_https_port      = var.https_port
  health_check_path        = var.health_check_path
  tags                     = var.tags
  sku                      = var.azure_lb_sku
  enable_waf               = var.enable_waf
}
```

## Atualizações no Outputs do Módulo Principal (`main/outputs.tf`)

```hcl
output "load_balancer_id" {
  description = "ID do load balancer (específico do provedor)"
  value = var.provider_type == "azure" ? module.azure[0].load_balancer_id :
          var.provider_type == "aws" ? module.aws[0].load_balancer_arn :
          var.provider_type == "gcp" ? module.gcp[0].load_balancer_id :
          module.digitalocean[0].load_balancer_id
}

output "load_balancer_ip" {
  description = "Endereço IP do load balancer"
  value = var.provider_type == "azure" ? module.azure[0].load_balancer_ip :
          var.provider_type == "aws" ? module.aws[0].load_balancer_dns_name :
          var.provider_type == "gcp" ? module.gcp[0].load_balancer_ip :
          module.digitalocean[0].load_balancer_ip
}
```

## Considerações Importantes

1. **Escolha entre Load Balancer e Application Gateway**
   - O Azure Load Balancer é principalmente Layer 4 (TCP/UDP)
   - Para funcionalidades Layer 7 (HTTP/HTTPS) com SSL termination, WAF, etc., o Application Gateway é mais adequado
   - A implementação deve ser flexível para suportar ambos, dependendo dos requisitos

2. **Modelo de Custo**
   - Load Balancer: Cobrado por regra e por hora
   - Application Gateway: Mais caro, cobrado por hora e por transferência de dados
   - Documentar claramente as implicações de custo para que os usuários possam fazer escolhas informadas

3. **Restrições Regionais**
   - Certos recursos podem não estar disponíveis em todas as regiões do Azure
   - Adicionar validações para garantir compatibilidade regional

4. **Considerações de Rede**
   - O Azure exige configuração de VNet e subnets específicas
   - Diferente de outros provedores, o Azure tem considerações específicas de rede

5. **Integração com Instâncias Existentes**
   - Documentar como integrar o load balancer com VMs, VMSS, AKS, e outros serviços do Azure
   - Fornecer exemplos para cada cenário

6. **Segurança**
   - Implementar Network Security Groups adequados
   - Configurar regras de firewall recomendadas
   - Garantir que os certificados SSL sejam armazenados de forma segura (usar Key Vault quando possível)

7. **Monitoramento**
   - Integrar com Azure Monitor
   - Configurar logs de diagnóstico
   - Definir alertas recomendados

## Plano de Implementação

1. **Fase 1: Implementação Básica**
   - Criar o módulo Azure com suporte a HTTP
   - Integrar com o módulo principal
   - Testar com aplicação simples

2. **Fase 2: Suporte a HTTPS**
   - Adicionar suporte para SSL/TLS via Application Gateway
   - Implementar gerenciamento de certificados
   - Testar com domínios personalizados

3. **Fase 3: Recursos Avançados**
   - Implementar WAF
   - Adicionar suporte para routing avançado
   - Integrar com Azure Monitor para logs e métricas
   - Configurar alertas e dashboards

4. **Fase 4: Documentação e Exemplos**
   - Atualizar README.md com exemplos específicos do Azure
   - Criar terraform-docs para auto-documentação
   - Adicionar exemplos para diferentes cenários (AKS, VM, VMSS)

## Cronograma Estimado

- **Fase 1**: 3-5 dias
- **Fase 2**: 3-5 dias
- **Fase 3**: 5-7 dias
- **Fase 4**: 2-3 dias

Total estimado: 13-20 dias de trabalho

## Referências

- [Documentação do Azure Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-overview)
- [Documentação do Azure Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/overview)
- [Terraform Provider Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Padrões de Load Balancing no Azure](https://docs.microsoft.com/en-us/azure/architecture/guide/technology-choices/load-balancing-overview)

