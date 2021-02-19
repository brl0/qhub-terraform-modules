resource "null_resource" "dependency_getter" {
  triggers = {
    my_dependencies = join(",", var.dependencies)
  }
}

data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  namespace  = var.namespace
  repository = data.helm_repository.jetstack.metadata[0].name
  chart      = "cert-manager"
  # values     = [file("${path.module}/cert-manager.yaml")]
  # values = concat([
  #   file("${path.module}/cert-manager.yaml"),
  #   jsonencode({
  #     "cert-manager" = {
  #       affinity = local.affinity
  #       cainjector = {
  #         affinity = local.affinity
  #       }
  #       webhook = {
  #         affinity = local.affinity
  #       }
  #     }
  #   }),
  # ])
  set {
    name  = "installCRDs"
    value = "true"
  }
  depends_on = [
    null_resource.dependency_getter,
  ]
}

data "helm_repository" "ingress-nginx" {
  name = "ingress-nginx"
  url  = "https://kubernetes.github.io/ingress-nginx"
}

resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  namespace  = var.namespace
  repository = data.helm_repository.ingress-nginx.metadata[0].name
  chart      = "ingress-nginx"
  values     = [file("${path.module}/ingress-nginx.yaml")]
  # values = concat([
  #   file("${path.module}/ingress-nginx.yaml"),
  #   jsonencode({
  #     "nginx-ingress" = {
  #       controller = {
  #         affinity = local.affinity
  #         livenessProbe = {
  #           timeoutSeconds = 20
  #         }
  #       }
  #       defaultBackend = {
  #         affinity = local.affinity
  #       }
  #     }
  #   }),
  # ])
  depends_on = [
    helm_release.cert-manager,
  ]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on      = [helm_release.ingress-nginx]
  create_duration = "30s"
}

resource "helm_release" "clusterissuer" {
  name       = "clusterissuer"
  chart      = "${path.module}/chart"
  values     = [file("${path.module}/clusterissuer.yaml")]
  depends_on = [time_sleep.wait_30_seconds]
}

resource "null_resource" "dependency_setter" {
  depends_on = [
    helm_release.clusterissuer,
    # List resource(s) that will be constructed last within the module.
  ]
}
