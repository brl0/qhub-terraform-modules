
variable "name" {
  description = "Prefix name to assign to azure kubernetes cluster"
  type        = string
}

# `az account list-locations`
variable "location" {
  description = "Location for GCP Kubernetes cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of kuberenetes"
  type        = string
}

variable "environment" {
  description = "Location for GCP Kubernetes cluster"
  type        = string
}


variable "node_groups" {
  description = "Node pools to add to Azure Kubernetes Cluster"
  type        = list(map(any))
}

# variable "node_labels" {
#   description = "Additional tags to apply to each node pool"
#   type        = map
#   default     = {}
# }


# unused
# variable "tags" {
#   description = "Additional tags to apply to each kuberentes resource"
#   type        = map
#   default     = {}
# }

