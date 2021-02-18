resource "null_resource" "dependency_getter" {
  triggers = {
    my_dependencies = join(",", var.dependencies)
  }
}

resource "kubernetes_namespace" "namespace_ingress_nginx" {
  metadata {
    labels = {
      "app.kubernetes.io/instance" = "ingress-nginx"
      "app.kubernetes.io/name"     = "ingress-nginx"
    }
    name = "ingress-nginx"
  }
  depends_on = [
    null_resource.dependency_getter
  ]
}

data "helm_repository" "ingress-nginx" {
  name = "ingress-nginx"
  url  = "https://kubernetes.github.io/ingress-nginx"
}

resource "helm_release" "ingress-nginx" {
  name      = "ingress-nginx"
  namespace = "dev"
  repository = data.helm_repository.ingress-nginx.metadata[0].name
  chart      = "ingress-nginx"
  version    = "3.23.0"
  values = [
    file("${path.module}/values.yaml"),
  ]
  depends_on = [
    kubernetes_namespace.namespace_ingress_nginx,
  ]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.ingress-nginx]
  create_duration = "30s"
  triggers = {
    ingress_helm = helm_release.ingress-nginx
  }
}

resource "null_resource" "dependency_setter" {
  depends_on = [
    time_sleep.wait_30_seconds.triggers["ingress_helm"],
    # List resource(s) that will be constructed last within the module.
  ]
}
