# Exemplo de implementação do Load Balancer para Azure
#
# Este exemplo demonstra como utilizar o módulo abstrato de Load Balancing
# configurado para o provedor Azure.

provider "azurerm" {
  features {}
}

# Cria um grupo de recursos para conter todos os recursos relacionados
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}

# Cria uma rede virtual para o load balancer
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Cria uma sub-rede para o load balancer
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Cria um endereço IP público para o load balancer
resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Utiliza o módulo específico de load balancing do Azure
module "load_balancer" {
  source = "../../../modules/load_balancing/azure"

  # Configuração geral
  name                = "example-lb"
  environment         = "development"
  
  # Configurações específicas do Azure
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location
  public_ip_id         = azurerm_public_ip.example.id
  subnet_id            = azurerm_subnet.example.id
  enable_https         = true
  https_certificate    = null # Para uso em produção, configure um certificado
  
  backend_address_pool_name = "example-backend-pool"
  
  health_probe_name           = "example-health-probe"
  health_probe_protocol       = "Http"
  health_probe_port           = 80
  health_probe_request_path   = "/"
  health_probe_interval       = 15
  health_probe_unhealthy_threshold = 2
  
  frontend_port_name     = "example-frontend-port"
  frontend_port          = 80
  frontend_port_protocol = "Tcp"
  backend_port           = 80
}

# Demonstração de criação de máquinas virtuais para backend do load balancer
resource "azurerm_network_interface" "example" {
  count               = 2
  name                = "example-nic-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associa as interfaces de rede ao pool de backend do load balancer
resource "azurerm_network_interface_backend_address_pool_association" "example" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.example[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = module.load_balancer.backend_pool_id
}

# Cria máquinas virtuais para servir como backend do load balancer
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
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "Bem-vindo ao servidor ${count.index}" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
    EOF
  )
}

# Saídas do exemplo
output "load_balancer_ip" {
  description = "Endereço IP público do Load Balancer"
  value       = azurerm_public_ip.example.ip_address
}

output "load_balancer_url" {
  description = "URL do Load Balancer"
  value       = "http://${azurerm_public_ip.example.ip_address}"
}

output "backend_servers" {
  description = "Endereços IP privados dos servidores de backend"
  value       = azurerm_network_interface.example[*].private_ip_address
}

