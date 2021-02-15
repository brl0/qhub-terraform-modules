resource "null_resource" "dependency_getter" {
  triggers = {
    my_dependencies = join(",", var.dependencies)
  }
}

data "local_file" "nginx-deployment" {
  filename = "${path.module}/deploy.yaml"
}

locals {
  resources = split("\n---\n", local_file.nginx-deployment.content)
}

resource "k8s_manifest" "nginx-deployment" {
  count = length(local.resources)
  content = local.resources[count.index]
}

resource "null_resource" "dependency_setter" {
  depends_on = [
    kubernetes_deployment.deployment_ingress_nginx_controller,
    # List resource(s) that will be constructed last within the module.
  ]
}
