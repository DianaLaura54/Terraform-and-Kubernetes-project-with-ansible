# Main Terraform Configuration for Kubernetes Infrastructure
# This example uses local Kubernetes (minikube/kind) but can be adapted for cloud providers

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}

# Create Namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    app_name     = "demo-app"
    environment  = var.environment
    log_level    = "info"
    database_url = "postgres://db:5432/myapp"
  }
}

# Secret for sensitive data
resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "app-secrets"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  type = "Opaque"

  data = {
    db_password = base64encode("changeme123")
    api_key     = base64encode("super-secret-key")
  }
}

# Deployment for the application
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "demo-app"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app         = "demo-app"
      environment = var.environment
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "demo-app"
      }
    }

    template {
      metadata {
        labels = {
          app         = "demo-app"
          environment = var.environment
        }
      }

      spec {
        container {
          name  = "app"
          image = var.app_image
          
          port {
            container_port = 80
            name          = "http"
          }

          env {
            name = "APP_NAME"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "app_name"
              }
            }
          }

          env {
            name = "ENVIRONMENT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "environment"
              }
            }
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "db_password"
              }
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Service to expose the application
resource "kubernetes_service" "app_service" {
  metadata {
    name      = "demo-app-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "demo-app"
    }
  }

  spec {
    selector = {
      app = "demo-app"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = var.service_type
  }
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "app_hpa" {
  metadata {
    name      = "demo-app-hpa"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    min_replicas = var.app_replicas
    max_replicas = var.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}

# Ingress (optional - uncomment if using ingress controller)
resource "kubernetes_ingress_v1" "app_ingress" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "demo-app-ingress"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = var.app_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.app_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
