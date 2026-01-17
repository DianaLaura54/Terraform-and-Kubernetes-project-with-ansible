.PHONY: help init plan apply destroy clean status logs port-forward k8s-apply k8s-delete jenkins-deploy jenkins-password jenkins-port-forward

# Variables
NAMESPACE := demo-app
JENKINS_NAMESPACE := jenkins
SERVICE := demo-app-service
JENKINS_SERVICE := jenkins
LOCAL_PORT := 8080
SERVICE_PORT := 80
JENKINS_PORT := 8080

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Terraform targets:"
	@echo "  init           - Initialize Terraform"
	@echo "  plan           - Plan Terraform changes"
	@echo "  apply          - Apply Terraform configuration"
	@echo "  destroy        - Destroy Terraform resources"
	@echo ""
	@echo "Kubernetes targets:"
	@echo "  k8s-apply      - Apply Kubernetes manifests"
	@echo "  k8s-delete     - Delete Kubernetes resources"
	@echo "  status         - Show cluster status"
	@echo "  logs           - Show application logs"
	@echo "  port-forward   - Port forward to service"
	@echo ""
	@echo "Jenkins targets:"
	@echo "  jenkins-deploy        - Deploy Jenkins to Kubernetes"
	@echo "  jenkins-password      - Get Jenkins initial admin password"
	@echo "  jenkins-port-forward  - Port forward to Jenkins"
	@echo "  jenkins-logs          - Show Jenkins logs"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean          - Clean Terraform files"


init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply

destroy:
	cd terraform && terraform destroy


k8s-apply:
	kubectl apply -f kubernetes/deployment.yaml

k8s-delete:
	kubectl delete -f kubernetes/deployment.yaml

status:
	@echo "=== Namespaces ==="
	kubectl get namespaces | grep $(NAMESPACE) || echo "Namespace not found"
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE)
	@echo ""
	@echo "=== Services ==="
	kubectl get svc -n $(NAMESPACE)
	@echo ""
	@echo "=== Deployments ==="
	kubectl get deployments -n $(NAMESPACE)
	@echo ""
	@echo "=== HPA ==="
	kubectl get hpa -n $(NAMESPACE)

logs:
	kubectl logs -f -l app=demo-app -n $(NAMESPACE)

port-forward:
	@echo "Forwarding localhost:$(LOCAL_PORT) -> $(SERVICE):$(SERVICE_PORT)"
	@echo "Access the application at http://localhost:$(LOCAL_PORT)"
	kubectl port-forward svc/$(SERVICE) $(LOCAL_PORT):$(SERVICE_PORT) -n $(NAMESPACE)


jenkins-deploy:
	kubectl apply -f kubernetes/jenkins.yaml
	@echo "Waiting for Jenkins to be ready..."
	kubectl wait --for=condition=ready pod -l app=jenkins -n $(JENKINS_NAMESPACE) --timeout=10m
	@echo "Jenkins deployed successfully!"
	@echo "Get password with: make jenkins-password"
	@echo "Access Jenkins with: make jenkins-port-forward"

jenkins-password:
	@echo "Jenkins Initial Admin Password:"
	@kubectl exec -it deployment/$(JENKINS_SERVICE) -n $(JENKINS_NAMESPACE) -- cat /var/jenkins_home/secrets/initialAdminPassword

jenkins-port-forward:
	@echo "Forwarding localhost:$(JENKINS_PORT) -> jenkins:8080"
	@echo "Access Jenkins at http://localhost:$(JENKINS_PORT)/jenkins"
	kubectl port-forward svc/$(JENKINS_SERVICE) $(JENKINS_PORT):8080 -n $(JENKINS_NAMESPACE)

jenkins-logs:
	kubectl logs -f deployment/$(JENKINS_SERVICE) -n $(JENKINS_NAMESPACE)

jenkins-status:
	@echo "=== Jenkins Deployment ==="
	kubectl get deployment jenkins -n $(JENKINS_NAMESPACE)
	@echo ""
	@echo "=== Jenkins Pods ==="
	kubectl get pods -l app=jenkins -n $(JENKINS_NAMESPACE)
	@echo ""
	@echo "=== Jenkins Service ==="
	kubectl get svc jenkins -n $(JENKINS_NAMESPACE)
	@echo ""
	@echo "=== Jenkins PVC ==="
	kubectl get pvc -n $(JENKINS_NAMESPACE)

jenkins-delete:
	kubectl delete -f kubernetes/jenkins.yaml


clean:
	cd terraform && rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup tfplan


dev-start:
	minikube start
	$(MAKE) init
	$(MAKE) apply

dev-stop:
	$(MAKE) destroy
	minikube stop
