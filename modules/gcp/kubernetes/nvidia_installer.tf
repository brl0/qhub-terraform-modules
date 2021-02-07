resource "kubernetes_daemonset" "nvidia_installer" {
  count = length(concat([for node_group in local.merged_node_groups : node_group.guest_accelerators])) == 0 ? 0 : 1

  metadata {
    name      = "nvidia-driver-installer"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "nvidia-driver-installer"
    }
  }

  spec {
    selector {
      match_labels = {
        "k8s-app" = "nvidia-driver-installer"
      }
    }

    strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          name      = "nvidia-driver-installer"
          "k8s-app" = "nvidia-driver-installer"
        }
      }

      spec {
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "cloud.google.com/gke-accelerator"
                  operator = "Exists"
                }
              }
            }
          }
        }
        toleration {
          operator = "Exists"
        }
        host_network = true
        host_pid     = true
        volume {
          name = "dev"
          host_path {
            path = "/dev"
          }
        }
        volume {
          name = "vulkan-icd-mount"
          host_path {
            path = "/home/kubernetes/bin/nvidia/vulkan/icd.d"
          }
        }
        volume {
          name = "nvidia-install-dir-host"
          host_path {
            path = "/home/kubernetes/bin/nvidia"
          }
        }
        volume {
          name = "root-mount"
          host_path {
            path = "/"
          }
        }
        init_container {
          image = "gcr.io/cos-cloud/cos-gpu-installer@sha256:8d86a652759f80595cafed7d3dcde3dc53f57f9bc1e33b27bc3cfa7afea8d483"
          name  = "nvidia-driver-installer"
          resources {
            requests = {
              cpu = 0.15
            }
          }
          security_context {
            privileged = true
          }
          env {
            name  = "NVIDIA_INSTALL_DIR_HOST"
            value = "/home/kubernetes/bin/nvidia"
          }
          env {
            name  = "NVIDIA_INSTALL_DIR_CONTAINER"
            value = "/usr/local/nvidia"
          }
          env {
            name  = "VULKAN_ICD_DIR_HOST"
            value = "/home/kubernetes/bin/nvidia/vulkan/icd.d"
          }
          env {
            name  = "VULKAN_ICD_DIR_CONTAINER"
            value = "/etc/vulkan/icd.d"
          }
          env {
            name  = "ROOT_MOUNT_DIR"
            value = "/root"
          }
          volume_mount {
            name       = "nvidia-install-dir-host"
            mount_path = "/usr/local/nvidia"
          }
          volume_mount {
            name       = "vulkan-icd-mount"
            mount_path = "/etc/vulkan/icd.d"
          }
          volume_mount {
            name       = "dev"
            mount_path = "/dev"
          }
          volume_mount {
            name       = "root-mount"
            mount_path = "/root"
          }
        }
        container {
          image = "gcr.io/google-containers/pause:2.0"
          name  = "pause"
        }
      }
    }
  }
}
