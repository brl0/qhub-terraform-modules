resource "null_resource" "dependency_getter" {
  triggers = {
    my_dependencies = join(",", var.dependencies)
  }
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
  values     = concat([
    file("${path.module}/values.yaml"),
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
    null_resource.dependency_getter,
  ]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on      = [helm_release.ingress-nginx]
  create_duration = "30s"
}

resource "null_resource" "dependency_setter" {
  depends_on = [
    time_sleep.wait_30_seconds,
    # List resource(s) that will be constructed last within the module.
  ]
}
