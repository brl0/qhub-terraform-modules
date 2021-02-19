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
  values = concat([
    file("${path.module}/cert-manager-values.yaml"),
    jsonencode({
      "cert-manager" = {
        affinity = local.affinity
        cainjector = {
          affinity = local.affinity
        }
        webhook = {
          affinity = local.affinity
        }
      }
    }),
  ])
  set {
    name  = "installCRDs"
    value = "true"
  }
  depends_on = [
    null_resource.dependency_getter,
  ]
}
resource "time_sleep" "wait_10_seconds" {
  depends_on      = [helm_release.cert-manager]
  create_duration = "10s"
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
  values = concat([
    file("${path.module}/ingress-nginx-values.yaml"),
    jsonencode({
      "nginx-ingress" = {
        controller = {
          livenessProbe = {
            timeoutSeconds = 20
          }
        }
      }
    }),
  ])
  depends_on = [
    time_sleep.wait_10_seconds,
  ]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on      = [helm_release.ingress-nginx]
  create_duration = "30s"
}

resource "helm_release" "clusterissuer" {
  name  = "clusterissuer"
  chart = "${path.module}/chart"
  force_update = true
  replace = true
  values = [
    file("${path.module}/clusterissuer-values.yaml"),
    file("${path.module}/cert-manager-values.yaml"),
  ]
  depends_on = [time_sleep.wait_30_seconds]
}

resource "null_resource" "dependency_setter" {
  depends_on = [
    helm_release.clusterissuer,
    # List resource(s) that will be constructed last within the module.
  ]
}
