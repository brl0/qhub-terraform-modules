resource "kubernetes_service_account" "main" {
  metadata {
    name = "${var.name}-jupyterhub"
    namespace = var.namespace
  }
}

resource "kubernetes_role" "main" {
  metadata {
    name = "${var.name}-jupyterhub"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "main" {
  metadata {
    name = "${var.name}-jupyterhub"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.main.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.main.metadata.0.name
    namespace = var.namespace
  }
}