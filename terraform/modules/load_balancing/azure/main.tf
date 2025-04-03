# Azure Load Balancer Module
# Este módulo implementa um balanceador de carga no Azure para aplicações NestJS

resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.main[0].name : var.resource_group_name
}

# Endereço IP público para o Load Balancer
resource "azurerm_public_ip" "main" {
  name                = "${var.name}-ip"
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = var.load_balancer_sku
  domain_name_label   = var.domain_name_label
  tags                = var.tags
}

# Load Balancer principal
resource "azurerm_lb" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = local.resource_group_name
  sku                 = var.load_balancer_sku

  frontend_ip_configuration {
    name                 = "${var.name}-frontend-ip"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = var.tags
}

# Backend Pool do Load Balancer
resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.name}-backend-pool"
  loadbalancer_id = azurerm_lb.main.id
}

# Health Probe HTTP
resource "azurerm_lb_probe" "http" {
  count               = var.enable_http ? 1 : 0
  name                = "${var.name}-http-probe"
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Http"
  port                = var.http_port
  request_path        = var.health_check_path
  interval_in_seconds = var.health_check_interval
  number_of_probes    = var.health_check_threshold
}

# Health Probe HTTPS
resource "azurerm_lb_probe" "https" {
  count               = var.enable_https ? 1 : 0
  name                = "${var.name}-https-probe"
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Https"
  port                = var.https_port
  request_path        = var.health_check_path
  interval_in_seconds = var.health_check_interval
  number_of_probes    = var.health_check_threshold
}

# Regra HTTP
resource "azurerm_lb_rule" "http" {
  count                          = var.enable_http ? 1 : 0
  name                           = "${var.name}-http-rule"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = var.http_port
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.http[0].id
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false
}

# Regra HTTPS
resource "azurerm_lb_rule" "https" {
  count                          = var.enable_https ? 1 : 0
  name                           = "${var.name}-https-rule"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = var.https_port
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.https[0].id
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false
}

# Configuração NAT para acesso SSH, se habilitado
resource "azurerm_lb_nat_rule" "ssh" {
  count                          = var.enable_ssh ? length(var.ssh_port_ranges) : 0
  name                           = "${var.name}-ssh-nat-rule-${count.index}"
  resource_group_name            = local.resource_group_name
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = var.ssh_port_ranges[count.index]
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
}

# Grupo de segurança de rede (opcional)
resource "azurerm_network_security_group" "main" {
  count               = var.create_network_security_group ? 1 : 0
  name                = "${var.name}-nsg"
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = var.tags
}

# Regra para HTTP
resource "azurerm_network_security_rule" "http" {
  count                       = var.create_network_security_group && var.enable_http ? 1 : 0
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.allowed_cidr_blocks
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[0].name
}

# Regra para HTTPS
resource "azurerm_network_security_rule" "https" {
  count                       = var.create_network_security_group && var.enable_https ? 1 : 0
  name                        = "allow-https"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = var.allowed_cidr_blocks
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[0].name
}

# Regra para SSH
resource "azurerm_network_security_rule" "ssh" {
  count                       = var.create_network_security_group && var.enable_ssh ? 1 : 0
  name                        = "allow-ssh"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = var.ssh_port_ranges
  source_address_prefix       = var.admin_cidr_blocks
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[0].name
}

# Monitoramento (opcional)
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                      = var.enable_monitoring ? 1 : 0
  name                       = "${var.name}-monitoring"
  target_resource_id         = azurerm_lb.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "LoadBalancerAlertEvent"
    enabled  = true
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }

  log {
    category = "LoadBalancerProbeHealthStatus"
    enabled  = true
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
}
