helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade -i ngx-ingres ingress-nginx/ingress-nginx -f ingress.yaml
sleep 5
kubectl create namespace argocd
kubectl apply -f argocd-ingress-dev.yaml -n argocd

# Install external DNS
#helm upgrade --install external-dns external-dns/external-dns --values values.yaml