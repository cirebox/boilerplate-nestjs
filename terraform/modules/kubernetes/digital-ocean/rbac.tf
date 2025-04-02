# Configuração RBAC (Role-Based Access Control) para Kubernetes
# Define roles e bindings para limitar o acesso aos recursos do cluster

# Variáveis para configuração RBAC
variable "rbac_groups" {
  description = "Mapa de nomes de grupos e usuários para cada tipo de acesso"
  type = map(object({
    users = list(string)
    groups = list(string)
  }))
  default = {
    admin = {
      users = []
      groups = []
    }
    develop = {
      users = []
      groups = []
    }
    readonly = {
      users = []
      groups = []
    }
  }
}

variable "rbac_namespaces" {
  description = "Lista de namespaces para aplicar as roles (deixe vazio para usar ClusterRoles)"
  type    = list(string)
  default = []
}

# Configuração para utilizar o provedor kubernetes após a criação do cluster
data "digitalocean_kubernetes_cluster" "primary" {
  name = var.cluster_name
  depends_on = [
    digitalocean_kubernetes_cluster.primary
  ]
}

# ClusterRole para acesso de administrador
resource "kubernetes_cluster_role" "admin_role" {
  metadata {
    name = "custom-admin-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

# ClusterRole para desenvolvedores (acesso limitado)
resource "kubernetes_cluster_role" "develop_role" {
  metadata {
    name = "custom-develop-role"
  }

  # Acesso a recursos comuns usados por desenvolvedores
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # Acesso de leitura para recursos relacionados a rede
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # Acesso limitado a logs e eventos
  rule {
    api_groups = [""]
    resources  = ["events", "pods/log", "pods/exec"]
    verbs      = ["get", "list", "watch"]
  }
}

# ClusterRole para acesso somente leitura
resource "kubernetes_cluster_role" "readonly_role" {
  metadata {
    name = "custom-readonly-role"
  }

  # Acesso de leitura para recursos comuns
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "persistentvolumeclaims", "namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  # Acesso a logs e eventos
  rule {
    api_groups = [""]
    resources  = ["events", "pods/log"]
    verbs      = ["get", "list", "watch"]
  }
}

# ClusterRoleBindings para usuários administradores
resource "kubernetes_cluster_role_binding" "admin_binding" {
  metadata {
    name = "custom-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.admin_role.metadata[0].name
  }

  dynamic "subject" {
    for_each = var.rbac_groups.admin.users
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  dynamic "subject" {
    for_each = var.rbac_groups.admin.groups
    content {
      kind      = "Group"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }
}

# ClusterRoleBindings para desenvolvedores
resource "kubernetes_cluster_role_binding" "develop_binding" {
  metadata {
    name = "custom-develop-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.develop_role.metadata[0].name
  }

  dynamic "subject" {
    for_each = var.rbac_groups.develop.users
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  dynamic "subject" {
    for_each = var.rbac_groups.develop.groups
    content {
      kind      = "Group"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }
}

# ClusterRoleBindings para usuários somente leitura
resource "kubernetes_cluster_role_binding" "readonly_binding" {
  metadata {
    name = "custom-readonly-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.readonly_role.metadata[0].name
  }

  dynamic "subject" {
    for_each = var.rbac_groups.readonly.users
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  dynamic "subject" {
    for_each = var.rbac_groups.readonly.groups
    content {
      kind      = "Group"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }
}

# Roles específicas para namespaces (quando namespaces são especificados)
resource "kubernetes_role" "namespace_admin_role" {
  for_each = toset(var.rbac_namespaces)

  metadata {
    name      = "custom-admin-role"
    namespace = each.value
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role" "namespace_develop_role" {
  for_each = toset(var.rbac_namespaces)

  metadata {
    name      = "custom-develop-role"
    namespace = each.value
  }

  # Acesso a recursos comuns usados por desenvolvedores
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role" "namespace_readonly_role" {
  for_each = toset(var.rbac_namespaces)

  metadata {
    name      = "custom-readonly-role"
    namespace = each.value
  }

  # Acesso de leitura para recursos comuns
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "persistentvolumeclaims"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }
}

# RoleBindings para namespaces específicos
resource "kubernetes_role_binding" "namespace_admin_binding" {
  for_each = toset(var.rbac_namespaces)

  metadata {
    name      = "custom-admin-binding"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.namespace_admin_role[each.value].metadata[0].name
  }

  dynamic "subject" {
    for_each = var.rbac_groups.admin.users
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  dynamic "subject" {
    for_each = var.rbac_groups.admin.groups
    content {
      kind      = "Group"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }
}

resource "kubernetes_role_binding" "namespace_develop_binding" {
  for_each = toset(var.rbac_namespaces)

  metadata {
    name      = "custom-develop-binding"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.namespace_develop_role[each.value].metadata[0].name
  }

  dynamic "subject" {
    for_each = var.rbac_groups.develop.users
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  dynamic "subject" {
    for_each = var.rbac_groups.develop.groups
    content {
      kind      = "Group"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }
}

resource "kubernetes_role_binding" "namespace_readonly_binding" {
  for_each = toset(var.rbac_namespaces)

  metadata {
    name      = "custom-readonly-binding"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.namespace_readonly_role[each.value].metadata[0].name
  }

  dynamic "subject" {
    for_each = var.rbac_groups.readonly.users
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  dynamic "subject" {
    for_each = var.rbac_groups.readonly.groups
    content {
      kind      = "Group"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }
}

# Outputs para facilitar a verificação da configuração RBAC
output "rbac_roles" {
  description = "Lista de roles RBAC criadas"
  value = {
    cluster_roles = {
      admin    = kubernetes_cluster_role.admin_role.metadata[0].name
      develop  = kubernetes_cluster_role.develop_role.metadata[0].name
      readonly = kubernetes_cluster_role.readonly_role.metadata[0].name
    }
    namespace_roles = var.rbac_namespaces
  }
}

