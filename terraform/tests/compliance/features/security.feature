Feature: Regras de Segurança para Infraestrutura do Boilerplate NestJS
  Como um administrador de segurança
  Eu quero garantir que a infraestrutura está configurada com práticas de segurança
  Para que os recursos sejam protegidos adequadamente

  # Regras gerais de segurança
  Scenario: Garantir que todos os recursos possuem tags apropriadas
    Given I have any resource defined
    Then it must contain tags
    And its tags must contain "environment"
    And its tags must contain "managed-by"
    And its tags must contain "project"

  # Regras para bancos de dados
  Scenario: Garantir que os bancos de dados PostgreSQL estão configurados com segurança
    Given I have digitalocean_database_cluster defined
    When its engine equals "pg"
    Then it must contain private_network
    And its private_network must be true
    And it must contain node_count
    And its node_count must be greater than 1
    And it must have backups enabled

  Scenario: Garantir que os bancos de dados têm criptografia em trânsito ativada
    Given I have digitalocean_database_cluster defined
    Then it must have everyauth_secured_communications enabled

  # Regras para Kubernetes
  Scenario: Garantir que os clusters Kubernetes estão protegidos
    Given I have digitalocean_kubernetes_cluster defined
    Then it must contain auto_upgrade
    And its auto_upgrade must be true
    And it must contain surge_upgrade
    And its surge_upgrade must be true
    And its tags must contain "protected"

  Scenario: Garantir que os clusters Kubernetes usam versões atualizadas
    Given I have digitalocean_kubernetes_cluster defined
    And its version must match the "^1\.(2[4-9]|[3-9][0-9])\." regex

  Scenario: Garantir que os clusters Kubernetes têm RBAC ativado
    Given I have digitalocean_kubernetes_cluster defined
    Then it must contain rbac
    And its rbac must be true

  # Regras para recursos de rede
  Scenario: Garantir que as VPCs estão configuradas corretamente
    Given I have digitalocean_vpc defined
    Then it must contain description
    And it must contain ip_range
    And its ip_range must not be "0.0.0.0/0"

  Scenario: Garantir que as regras de firewall estão configuradas de forma restritiva
    Given I have digitalocean_firewall defined
    Then it must contain inbound_rule
    And it must contain outbound_rule
    And its inbound_rule must not have any "port_range" with "0-65535"
    And its inbound_rule must not have source_addresses with "0.0.0.0/0" for protocols with "tcp" and ports not "80,443"

  # Regras para recursos de armazenamento
  Scenario: Garantir que os buckets de armazenamento são privados
    Given I have digitalocean_spaces_bucket defined
    Then it must contain acl
    And its acl must be "private"

  Scenario: Garantir que versões de objetos estão habilitadas para buckets
    Given I have digitalocean_spaces_bucket defined
    Then it must contain versioning
    And its versioning must be true

  # Regras para recursos de monitoramento
  Scenario: Garantir que alertas de CPU estão configurados
    Given I have digitalocean_monitor_alert defined
    When its compare equals "GreaterThan"
    And its type equals "v1/insights/droplet/cpu"
    Then its value must be less than 80

  Scenario: Garantir que alertas de memória estão configurados
    Given I have digitalocean_monitor_alert defined
    When its compare equals "GreaterThan"
    And its type equals "v1/insights/droplet/memory_utilization_percent"
    Then its value must be less than 80

  # Regras para tokens e credenciais
  Scenario: Garantir que tokens não estão expostos como valores diretos
    Given I have variable defined
    When its name equals "do_token"
    Then its value must contain environment variable
    And its sensitive must be true

  # Regras para droplets
    Scenario: Garantir que as droplets têm backups ativados
    Given I have digitalocean_droplet defined
    Then it must contain backups
    And its backups must be true

  Scenario: Garantir que as droplets têm monitoramento ativado
    Given I have digitalocean_droplet defined
    Then it must contain monitoring
    And its monitoring must be true

  Scenario: Garantir que os discos das droplets são criptografados
    Given I have digitalocean_volume defined
    Then it must contain encryption
    And its encryption must be true

  # Regras para prevenção de destruição acidental
  Scenario: Garantir que recursos críticos estão protegidos contra destruição acidental
    Given I have digitalocean_kubernetes_cluster defined
    Then it must contain lifecycle
    And its lifecycle must contain prevent_destroy
    And its lifecycle.prevent_destroy must be true

