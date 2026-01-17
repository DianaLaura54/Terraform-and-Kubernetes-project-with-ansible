# Outputs for Terraform Kubernetes Configuration

output "namespace" {
  description = "The namespace where resources are deployed"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}

output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = kubernetes_deployment.app.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service"
  value       = kubernetes_service.app_service.metadata[0].name
}

output "service_type" {
  description = "Type of the Kubernetes service"
  value       = kubernetes_service.app_service.spec[0].type
}

output "app_url" {
  description = "Application URL (if using LoadBalancer or NodePort)"
  value       = var.service_type == "LoadBalancer" ? "http://${kubernetes_service.app_service.status[0].load_balancer[0].ingress[0].ip}" : "Use kubectl port-forward"
}

output "configmap_name" {
  description = "Name of the ConfigMap"
  value       = kubernetes_config_map.app_config.metadata[0].name
}

output "secret_name" {
  description = "Name of the Secret"
  value       = kubernetes_secret.app_secrets.metadata[0].name
}

output "hpa_name" {
  description = "Name of the Horizontal Pod Autoscaler"
  value       = kubernetes_horizontal_pod_autoscaler_v2.app_hpa.metadata[0].name
}

output "ingress_enabled" {
  description = "Whether ingress is enabled"
  value       = var.enable_ingress
}

output "kubectl_commands" {
  description = "Useful kubectl commands"
  value = <<-EOT
    # View pods
    kubectl get pods -n ${kubernetes_namespace.app_namespace.metadata[0].name}
    
    # View service
    kubectl get svc -n ${kubernetes_namespace.app_namespace.metadata[0].name}
    
    # Port forward to access the app
    kubectl port-forward svc/${kubernetes_service.app_service.metadata[0].name} 8080:80 -n ${kubernetes_namespace.app_namespace.metadata[0].name}
    
    # View logs
    kubectl logs -f deployment/${kubernetes_deployment.app.metadata[0].name} -n ${kubernetes_namespace.app_namespace.metadata[0].name}
    
    # Scale deployment
    kubectl scale deployment/${kubernetes_deployment.app.metadata[0].name} --replicas=3 -n ${kubernetes_namespace.app_namespace.metadata[0].name}
  EOT
}

# Jenkins Outputs
output "jenkins_namespace" {
  description = "The namespace where Jenkins is deployed"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_service_name" {
  description = "Name of the Jenkins service"
  value       = kubernetes_service.jenkins.metadata[0].name
}

output "jenkins_url" {
  description = "Jenkins access URL"
  value       = "Use: kubectl port-forward svc/jenkins 8080:8080 -n ${kubernetes_namespace.jenkins.metadata[0].name}"
}

output "jenkins_initial_password_command" {
  description = "Command to get Jenkins initial admin password"
  value       = "kubectl exec -it deployment/jenkins -n ${kubernetes_namespace.jenkins.metadata[0].name} -- cat /var/jenkins_home/secrets/initialAdminPassword"
}

output "jenkins_commands" {
  description = "Useful Jenkins kubectl commands"
  value = <<-EOT
    # Port forward to Jenkins
    kubectl port-forward svc/jenkins 8080:8080 -n ${kubernetes_namespace.jenkins.metadata[0].name}
    
    # Get initial admin password
    kubectl exec -it deployment/jenkins -n ${kubernetes_namespace.jenkins.metadata[0].name} -- cat /var/jenkins_home/secrets/initialAdminPassword
    
    # View Jenkins logs
    kubectl logs -f deployment/jenkins -n ${kubernetes_namespace.jenkins.metadata[0].name}
    
    # Access Jenkins shell
    kubectl exec -it deployment/jenkins -n ${kubernetes_namespace.jenkins.metadata[0].name} -- /bin/bash
  EOT
}
