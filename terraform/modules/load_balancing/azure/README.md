# Módulo de Load Balancing para Azure

## Descrição

Este módulo implementa recursos de balanceamento de carga no Azure, permitindo a distribuição eficiente de tráfego entre instâncias de aplicação. O módulo suporta tanto o Azure Load Balancer (camada 4) quanto o Application Gateway (camada 7), dependendo das necessidades específicas da aplicação.

## Funcionalidades

- **Balanceamento de Carga HTTP/HTTPS**: Distribuição de tráfego web entre múltiplas instâncias
- **Health Checks Personalizáveis**: Monitoramento de saúde dos endpoints
- **Regras de Firewall Integradas**: Controle de tráfego com Network Security Groups
- **TLS/SSL Termination**: Gerenciamento de certificados via Azure Key Vault
- **Path-based Routing**: Roteamento de tráfego baseado em URLs (com Application Gateway)
- **Session Affinity**: Manutenção de sessões de usuário na mesma instância
- **Auto-scaling**: Ajuste automático de recursos baseado em métricas de tráfego
- **Logs de Acesso**: Registro detalhado do tráfego para análise e auditoria

## Pré-requisitos

- Azure Resource Group
- Virtual Network e Subnet configurados
- Provedor Azure configurado com permissões adequadas
- (Opcional) Azure Key Vault para certificados SSL

## Variáveis de Entrada

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:----------:|
| `resource_group_name` | Nome do Resource Group onde os recursos serão criados | `string` | n/a | sim |
| `location` | Região do Azure onde os recursos serão criados | `string` | n/a | sim |
| `name` | Nome do balanceador de carga | `string` | n/a | sim |
| `load_balancer_type` | Tipo de balanceador: "standard" ou "application_gateway" | `string` | `"standard"` | não |
| `virtual_network_name` | Nome da Virtual Network | `string` | n/a | sim |
| `subnet_name` | Nome da Subnet onde o balanceador será implantado | `string` | n/a | sim |
| `frontend_ports` | Lista de portas frontais para o balanceador | `list(number)` | `[80, 443]` | não |
| `backend_ports` | Lista de portas de backend para o balanceador | `list(number)` | `[80]` | não |
| `backend_address_pool_name` | Nome do pool de endereços de backend | `string` | `"backend-pool"` | não |
| `protocol` | Protocolo utilizado ("Tcp", "Udp", "Http", "Https") | `string` | `"Tcp"` | não |
| `enable_https` | Se deve habilitar HTTPS | `bool` | `false` | não |
| `ssl_certificate_name` | Nome do certificado SSL no Key Vault (se HTTPS habilitado) | `string` | `""` | não |
| `key_vault_id` | ID do Key Vault contendo o certificado (se HTTPS habilitado) | `string` | `""` | não |
| `health_check_path` | Caminho para o health check | `string` | `"/"` | não |
| `health_check_port` | Porta para o health check | `number` | `80` | não |
| `tags` | Tags a serem aplicadas aos recursos | `map(string)` | `{}` | não |

## Saídas

| Nome | Descrição |
|------|-----------|
| `load_balancer_id` | ID do balanceador de carga criado |
| `load_balancer_ip_address` | Endereço IP público do balanceador de carga |
| `load_balancer_fqdn` | Nome de domínio completo (FQDN) do balanceador de carga |
| `backend_address_pool_id` | ID do pool de endereços de backend |
| `health_probe_id` | ID da sonda de saúde (health probe) |

## Exemplo de Uso

### Load Balancer Básico

```hcl
module "azure_lb" {
  source = "../modules/load_balancing/azure"

  resource_group_name  = "meu-resource-group"
  location             = "brazilsouth"
  name                 = "app-load-balancer"
  virtual_network_name = "minha-vnet"
  subnet_name          = "frontend-subnet"
  
  frontend_ports       = [80]
  backend_ports        = [8080]
  protocol             = "Tcp"
  
  health_check_path    = "/health"
  health_check_port    = 8080
  
  tags = {
    Environment = "Produção"
    Application = "MeuApp"
  }
}
```

### Application Gateway com HTTPS

```hcl
module "azure_appgw" {
  source = "../modules/load_balancing/azure"

  resource_group_name  = "meu-resource-group"
  location             = "brazilsouth"
  name                 = "app-gateway"
  load_balancer_type   = "application_gateway"
  virtual_network_name = "minha-vnet"
  subnet_name          = "gateway-subnet"
  
  frontend_ports       = [80, 443]
  backend_ports        = [8080]
  protocol             = "Http"
  
  enable_https         = true
  ssl_certificate_name = "meu-certificado"
  key_vault_id         = "/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/meu-keyvault"
  
  health_check_path    = "/api/health"
  health_check_port    = 8080
  
  tags = {
    Environment = "Produção"
    Application = "MeuApp"
  }
}
```

### Uso com o Módulo Abstrato

```hcl
module "load_balancer" {
  source = "../modules/load_balancing/main"

  provider_name        = "azure"
  
  // Variáveis comuns
  name                 = "app-load-balancer"
  
  // Variáveis específicas do Azure
  azure_config = {
    resource_group_name  = "meu-resource-group"
    location             = "brazilsouth"
    virtual_network_name = "minha-vnet"
    subnet_name          = "frontend-subnet"
    load_balancer_type   = "standard"
  }
  
  ports = {
    frontend = [80, 443]
    backend  = [8080]
  }
  
  health_check = {
    path = "/health"
    port = 8080
  }
  
  tags = {
    Environment = "Produção"
    Application = "MeuApp"
  }
}
```

## Limitações Conhecidas

- O Azure Application Gateway não suporta UDP, apenas HTTP/HTTPS
- O balanceamento de carga IPv6 é suportado apenas no Azure Load Balancer Standard
- O WAF (Web Application Firewall) está disponível apenas com o Application Gateway v2

## Contribuição

Para contribuir com melhorias para este módulo:

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Implemente suas alterações
4. Execute os testes automatizados
5. Submeta um pull request

## Troubleshooting

### Problemas Comuns

- **Erro de Rede**: Verifique se a Virtual Network e Subnet estão configuradas corretamente
- **Falha nos Health Checks**: Confirme se a aplicação está respondendo no path e porta configurados
- **Problemas de Certificado**: Verifique as permissões do Key Vault e a validade do certificado

