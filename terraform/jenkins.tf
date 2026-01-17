# Jenkins Deployment Configuration
# This deploys Jenkins as a CI/CD server in Kubernetes

# Jenkins Namespace
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
    labels = {
      name       = var.jenkins_namespace
      managed-by = "terraform"
    }
  }
}

# Jenkins PersistentVolume for data persistence
resource "kubernetes_persistent_volume_claim" "jenkins_pvc" {
  metadata {
    name      = "jenkins-pvc"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.jenkins_storage_size
      }
    }
  }
}

# Jenkins ServiceAccount
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

# Jenkins RBAC - ClusterRole
resource "kubernetes_cluster_role" "jenkins" {
  metadata {
    name = "jenkins-admin"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/exec", "pods/log", "persistentvolumeclaims", "events"]
    verbs      = ["get", "list", "watch", "create", "delete", "update", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch", "create", "delete", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch", "create", "delete", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "watch"]
  }
}

# Jenkins RBAC - ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "jenkins" {
  metadata {
    name = "jenkins-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.jenkins.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins.metadata[0].name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

# Jenkins ConfigMap for configuration
resource "kubernetes_config_map" "jenkins_config" {
  metadata {
    name      = "jenkins-config"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    jenkins_opts = "--prefix=/jenkins"
    java_opts    = "-Xmx2048m -Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85"
  }
}

# Jenkins Deployment
resource "kubernetes_deployment" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    labels = {
      app = "jenkins"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "jenkins"
      }
    }

    template {
      metadata {
        labels = {
          app = "jenkins"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.jenkins.metadata[0].name

        security_context {
          fs_group = 1000
        }

        container {
          name  = "jenkins"
          image = var.jenkins_image

          port {
            name           = "http"
            container_port = 8080
          }

          port {
            name           = "jnlp"
            container_port = 50000
          }

          env {
            name  = "JAVA_OPTS"
            value = "-Xmx2048m -Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85"
          }

          env {
            name  = "JENKINS_OPTS"
            value = "--prefix=/jenkins"
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
          }

          volume_mount {
            name       = "jenkins-home"
            mount_path = "/var/jenkins_home"
          }

          liveness_probe {
            http_get {
              path = "/jenkins/login"
              port = 8080
            }
            initial_delay_seconds = 90
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 5
          }

          readiness_probe {
            http_get {
              path = "/jenkins/login"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        volume {
          name = "jenkins-home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jenkins_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# Jenkins Service
resource "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    labels = {
      app = "jenkins"
    }
  }

  spec {
    selector = {
      app = "jenkins"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }

    port {
      name        = "jnlp"
      port        = 50000
      target_port = 50000
    }

    type = var.jenkins_service_type
  }
}

# Jenkins Ingress (optional)
resource "kubernetes_ingress_v1" "jenkins_ingress" {
  count = var.enable_jenkins_ingress ? 1 : 0

  metadata {
    name      = "jenkins-ingress"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }

  spec {
    rule {
      host = var.jenkins_hostname

      http {
        path {
          path      = "/jenkins(/|$)(.*)"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.jenkins.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
