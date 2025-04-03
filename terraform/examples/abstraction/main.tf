/**
* Exemplo de migração para a nova interface abstrata de load balancing
* Este arquivo demonstra como migrar um módulo de aplicação existente que
* usa diretamente implementações específicas de provedor para usar a nova
* interface abstrata de load balancing.
*/

# --------------------------------------------------------------------------
# ANTES: Implementação específica de provedor (Digital Ocean)
# --------------------------------------------------------------------------

/**
* Na implementação anterior, o balanceador de carga era configurado diretamente
* no módulo de rede ou usando um módulo específico do provedor.
* Isso criava uma forte dependência com um provedor específico
* e dificultava a portabilidade para outros provedores.
*/

/*
module "app" {
  source = "../../modules/app"

  app_name        = "api-service"
  environment     = "production"
  container_image = "registry.example.com/api-service:latest"
  
  # Configuração direta de um balanceador de carga do Digital Ocean
  # que estava embutida no módulo de aplicação ou de rede
  droplet_ids     = module.kubernetes.node_ids
  region          = "nyc1"
  redirect_http_to_https = true
  forwarding_rules = [
    {
      entry_port      = 80
      entry_protocol  = "http"
      target_port     = 80
      target_protocol = "http"
    },
    {
      entry_port      = 443
      entry_protocol  = "https"
      target_port     = 80
      target_protocol = "http"
      certificate_id  = var.certificate_id
    }
  ]
  healthcheck = {
    port     = 80
    protocol = "http"
    path     = "/health"
  }
}
*/

# --------------------------------------------------------------------------
# DEPOIS: Uso da interface abstrata de load balancing
# --------------------------------------------------------------------------

/**
* Na nova implementação, usamos a interface abstrata de load balancing
* que é independente do provedor. Isso facilita a portabilidade e 
* a consistência entre diferentes ambientes e provedores de nuvem.
*/

# Definindo o provedor a ser usado
locals {
  cloud_provider = "digital-ocean" # Poderia ser "aws" ou "gcp"
}

# Módulo de aplicação (sem configurações específicas de balanceamento de carga)
module "app" {
  source = "../../modules/app"

  app_name        = "api-service"
  environment     = "production"
  container_image = "registry.example.com/api-service:latest"

  # Sem configurações de balanceamento de carga aqui
  # Elas foram movidas para o módulo de load balancing abaixo
}

# Módulo de load balancing abstrato
module "load_balancer" {
  source = "../../modules/load_balancing/main"

  # Configuração de qual provedor usar (via variável)
  provider_type = local.cloud_provider

  # Configurações comuns para todos os provedores
  name        = "api-service-lb"
  environment = "production"

  # Configuração de protocolo e portas
  protocols = {
    http  = true
    https = true
  }
  redirect_http_to_https = true

  # Configuração de regras de encaminhamento
  forwarding_rules = [
    {
      entry_port      = 80
      entry_protocol  = "http"
      target_port     = 80
      target_protocol = "http"
    },
    {
      entry_port      = 443
      entry_protocol  = "https"
      target_port     = 80
      target_protocol = "http"
    }
  ]

  # Verificação de saúde
  health_check = {
    port     = 80
    protocol = "http"
    path     = "/health"
    interval = 30
    timeout  = 5
    retries  = 3
  }

  # Configurações específicas para cada provedor são tratadas internamente
  # pelo módulo abstrato, baseadas no provider_type

  # Configurações específicas do Digital Ocean
  do_config = {
    region         = "nyc1"
    droplet_ids    = module.kubernetes.node_ids
    certificate_id = var.certificate_id
  }

  # Configurações específicas da AWS
  aws_config = {
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    certificate_arn    = "arn:aws:acm:region:account:certificate/certificate-id"
    security_group_ids = ["sg-12345678"]
  }

  # Configurações específicas do GCP
  gcp_config = {
    project         = "my-gcp-project"
    network         = "default"
    subnetwork      = "default"
    region          = "us-central1"
    ssl_certificate = "projects/my-gcp-project/global/sslCertificates/my-cert"
  }

  # Tags
  tags = {
    Service     = "api-service"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# --------------------------------------------------------------------------
# Benefícios da nova implementação:
# --------------------------------------------------------------------------
/**
* 1. Portabilidade: Mudança para outro provedor requer apenas alteração da
*    variável local.cloud_provider.
*
* 2. Consistência: Interface consistente para todos os provedores, com
*    configurações específicas passadas em blocos separados.
*
* 3. Clareza: Separação clara entre a lógica da aplicação e o balanceamento de carga.
*
* 4. Reusabilidade: Configurações de balanceamento de carga podem ser reutilizadas
*    entre várias aplicações, mantendo consistência.
*
* 5. Testabilidade: Interface padronizada facilita a criação de testes automatizados.
*/

# --------------------------------------------------------------------------
# Exemplo de como migrar para outro provedor (AWS):
# --------------------------------------------------------------------------
/*
locals {
  cloud_provider = "aws" # Alterado de "digital-ocean" para "aws"
}

# O restante do código permanece o mesmo! 
# O módulo interno se encarrega de usar o provedor correto.
*/

