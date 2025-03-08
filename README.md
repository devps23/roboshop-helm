# roboshop-helm

* add ingress repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
* helm upgrade -i ngx-ingres ingress-nginx/ingress-nginx -f ingress.yaml 
here ingress.yaml contains NLB Load balancer configuration
* controller:
  service:
  internal:
  enabled: false
  targetPorts:
  http: http
  https: http
  annotations:
  service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
  service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '60'
  service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: 'true'
  service.beta.kubernetes.io/aws-load-balancer-type: nlb
  service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-east-1:633788536644:certificate/274d4c80-dc76-4296-b3ed-d959cbe837ba
  service.beta.kubernetes.io/aws-load-balancer-ssl-ports: 443

* fetch argocd raw data and paste in argocd-dev.yaml
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
add ingress configuration in "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
* apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
  name: argocd
  namespace: argocd
  spec:
  ingressClassName: nginx
  rules:
    - host: argocd-ingress.pdevops72.online
      http:
      paths:
      - pathType: Prefix
      backend:
      service:
      name: argocd-server
      port:
      number: 443
      path: /
    
here argocd-server is a service in kubernetes , ingress will create NLB server ip address, ingress attach this ip address to host ,by using this
host we can expose this host outside
* create a namespace with name "argocd"
kubectl create namespace argocd
* create a pod with namespace argocd
kubectl apply -f argocd-dev.yaml -n argocd
* to get all namespace of the ingress
kubectl get ingress -A 

everytime adding
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm upgrade --install external-dns external-dns/external-dns --version 1.15.0

Flow ExternalDNS:
=================
ServiceAccount → IAM Role → Grants permissions to tools like ExternalDNS → ExternalDNS adds or updates DNS records based on Kubernetes resources (e.g., Service or Ingress).

So, while the ServiceAccount with an IAM role doesn't directly add services to DNS names, it enables tools like ExternalDNS to perform this action. Let me know if you'd like to explore this further or need a step-by-step guide for configuring it!

* To create a ServiceAccount in eks cluster, we need an IAM role.
* create an IAM role policy
resource "aws_iam_policy" ""{
policy = <<EOF
EOF
* }
visualizatsion:
===========
* User Request
  ↓
  Ingress (example.com/app)
  ↓
  Ingress Controller (e.g., ALB, NGINX)
  ↓
  Service (ClusterIP: app-service)
  ↓
  Pods (app-pod-1, app-pod-2)



 
