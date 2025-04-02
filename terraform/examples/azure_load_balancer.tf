# Exemplo de uso do módulo de Load Balancing do Azure
# Este exemplo demonstra como configurar um balanceador de carga no Azure
# utilizando a interface abstrata do módulo de load balancing

# Configuração do provedor Azure
provider "azurerm" {
  features {}
}

# Recursos de rede necessários para o balanceador de carga
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "backend" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Configuração de máquinas virtuais para o backend
resource "azurerm_network_interface" "example" {
  count               = 2
  name                = "example-nic-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  count               = 2
  name                = "example-vm-${count.index}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "Servidor ${count.index + 1}" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
    EOF
  )
}

# Uso do módulo de load balancing abstrato
module "load_balancer" {
  source = "../modules/load_balancing/main"

  # Configuração geral
  provider_name = "azure"
  name          = "webapp-lb"
  environment   = "dev"
  
  # Configurações específicas do Azure
  azure_resource_group_name = azurerm_resource_group.example.name
  azure_location            = azurerm_resource_group.example.location
  azure_virtual_network_id  = azurerm_virtual_network.example.id
  azure_subnet_id           = azurerm_subnet.backend.id
  
  # Configuração dos targets (backends)
  azure_backend_addresses = [
    {
      name      = "vm-1"
      ip_address = azurerm_network_interface.example[0].private_ip_address
    },
    {
      name      = "vm-2"
      ip_address = azurerm_network_interface.example[1].private_ip_address
    }
  ]
  
  # Configuração das portas e protocolos
  ports = {
    http = {
      port     = 80
      protocol = "Tcp"
      health_check = {
        path     = "/"
        port     = 80
        protocol = "Http"
      }
    }
    https = {
      port     = 443
      protocol = "Tcp"
      health_check = {
        path     = "/"
        port     = 443
        protocol = "Https"
      }
    }
  }
  
  # Configuração SSL (opcional)
  enable_ssl = true
  ssl_certificates = {
    example = {
      name                = "example-cert"
      key_vault_secret_id = "https://example-keyvault.vault.azure.net/secrets/example-cert"
    }
  }
  
  # Configurações avançadas
  waf_enabled         = true
  waf_mode            = "Prevention"
  enable_http2        = true
  connection_draining = true
  
  # Tags para recursos
  tags = {
    Environment = "Development"
    Project     = "NestJS Example"
    ManagedBy   = "Terraform"
  }
}

# Output para exibir o endereço do load balancer
output "load_balancer_ip" {
  description = "O endereço IP público do load balancer"
  value       = module.load_balancer.load_balancer_ip
}

output "load_balancer_fqdn" {
  description = "O nome de domínio completamente qualificado do load balancer"
  value       = module.load_balancer.load_balancer_fqdn
}

# Exemplo de como usar o load balancer para uma aplicação NestJS
# Este é um ponto de partida e você pode personalizar conforme necessário
resource "azurerm_app_service_plan" "example" {
  name                = "example-appserviceplan"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "example" {
  name                = "example-nestjs-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_id = azurerm_app_service_plan.example.id

  site_config {
    linux_fx_version = "NODE|14-lts"
    health_check_path = "/health"
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~14"
    "DATABASE_URL"                = "postgresql://user:password@db-host:5432/mydb"
    "NODE_ENV"                    = "production"
    "PORT"                        = "8080"
  }
}

# Comentário explicativo sobre como integrar com a aplicação NestJS
/*
Para integrar este load balancer com sua aplicação NestJS:

1. Certifique-se de que sua aplicação tenha um endpoint de health check (ex: /health)
2. Configure sua aplicação para escutar na porta definida nos parâmetros do load balancer
3. Para produção, adicione configurações de sessão persistente se necessário
4. Considere configurar auto-scaling para suas VMs ou serviços de aplicação
5. Monitore os logs e métricas do load balancer para otimizar o desempenho
*/

