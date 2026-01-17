# Variables for Terraform Kubernetes Configuration

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "minikube"
}

variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "demo-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "nginx:latest"
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 5
}

variable "service_type" {
  description = "Kubernetes service type (ClusterIP, NodePort, LoadBalancer)"
  type        = string
  default     = "ClusterIP"
}

variable "enable_ingress" {
  description = "Enable ingress resource"
  type        = bool
  default     = false
}

variable "app_hostname" {
  description = "Hostname for the application ingress"
  type        = string
  default     = "demo-app.local"
}

# Jenkins Variables
variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_image" {
  description = "Jenkins Docker image"
  type        = string
  default     = "jenkins/jenkins:lts"
}

variable "jenkins_storage_size" {
  description = "Storage size for Jenkins PVC"
  type        = string
  default     = "10Gi"
}

variable "jenkins_service_type" {
  description = "Kubernetes service type for Jenkins (ClusterIP, NodePort, LoadBalancer)"
  type        = string
  default     = "ClusterIP"
}

variable "enable_jenkins_ingress" {
  description = "Enable ingress for Jenkins"
  type        = bool
  default     = false
}

variable "jenkins_hostname" {
  description = "Hostname for Jenkins ingress"
  type        = string
  default     = "jenkins.local"
}
