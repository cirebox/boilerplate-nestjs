# Mapeamento explícito de providers para corrigir problemas de namespace

# Corrigir o problema do provider DigitalOcean
provider "digitalocean" {
  alias = "override"
  # Configuração mínima para evitar erros
  token = "dummy_token" # Será substituído pelas configurações do arquivo principal
}

# Corrigir o problema do provider Docker
provider "docker" {
  alias = "override"
  # Configuração mínima para evitar erros
  host = "unix:///var/run/docker.sock"
}

# Adicionar provider google-beta explicitamente
provider "google-beta" {
  alias = "override"
  # Sem configuração necessária, apenas para mapear o namespace correto
}

# Adicionar provider helm explicitamente
provider "helm" {
  alias = "override"
  # Sem configuração necessária, apenas para mapear o namespace correto
}

# Adicionar provider kubernetes explicitamente
provider "kubernetes" {
  alias = "override"
  # Sem configuração necessária, apenas para mapear o namespace correto
}

# Adicionar provider null explicitamente
provider "null" {
  alias = "override"
  # Sem configuração necessária, apenas para mapear o namespace correto
}

# Adicionar provider random explicitamente
provider "random" {
  alias = "override"
  # Sem configuração necessária, apenas para mapear o namespace correto
}
