aws eks update-kubeconfig --name dev-eks
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade -i ngx-ingres ingress-nginx/ingress-nginx -f ingress.yaml
sleep 5
kubectl create namespace argocd
kubectl apply -f argocd-ingress-dev.yaml -n argocd

LoadBalancer = $( kubectl get svc ngx-ingres-ingress-nginx-controller | grep ngx-ingres-ingress-nginx-controller | awk '{print$4}' )
echo $LoadBalancer
while [ true ]; do
    echo "please wait until load balancer is active"
    nslookup $LoadBalancer
    if [ $? -eq 0 ]; then
      echo "Load Balancer not found"
      break;
    fi
done
sleep 10
# to create external-dns tools  as POD in eks cluster
kubectl apply -f external-dns-dev.yaml
argocd login argocd-ingress.pdevops78.online --username admin --password $(argocd admin initial-password -n argocd | head -1) --insecure --grpc-web

#argocd login argocd-ingress.pdevops78.online --username admin --password yKeioaerpccoSuC9 --insecure --skip-test-tls --grpc-web
for app in frontend ; do
argocd app create {{app}} --repo https://github.com/devps23/roboshop-helm.git --path chart --dest-server https://kubernetes.default.svc --dest-namespace default.svc --grpc-web --values values/{{app}}.yaml
done


# Install external DNS
#helm upgrade --install external-dns external-dns/external-dns --values values.yaml