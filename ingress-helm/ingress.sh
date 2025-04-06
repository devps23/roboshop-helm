aws eks update-kubeconfig --name dev-eks
# add ingress repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# install ingress-nginx
helm upgrade -i ngx-ingres ingress-nginx/ingress-nginx -f ingress.yaml
# add load balancer service
LOAD_BALANCER=$(kubectl get svc ngx-ingres-ingress-nginx-controller | grep ngx-ingres-ingress-nginx-controller | awk '{print $4}')
# loop load balancer until
while true ; do
  echo "Waiting for Load Balancer to come to Active"
  nslookup $LOAD_BALANCER &>/dev/null
  if [ $? -eq 0 ]; then break ; fi
  sleep 5
done

#kubectl apply -f external-dns-dev.yaml
sleep 15
# create argocd namespace
kubectl create ns argocd
kubectl apply -f argocd-ingress-dev.yaml -n argocd


while true ; do
  argocd admin initial-password -n argocd &>/dev/null
  if [ $? -eq 0 ]; then break ; fi
  sleep 5
done


# install elk
helm repo add elastic https://helm.elastic.co
helm repo update
kubectl create -f https://download.elastic.co/downloads/eck/2.16.1/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.16.1/operator.yaml
helm install es-kb-quickstart elastic/eck-stack -n elastic-stack --create-namespace
kubectl apply -f elk.yaml
ES_PASSWORD=$(kubectl get secrets -n elastic-stack elasticsearch-es-elastic-user -o json | jq '.data.elastic' | sed -e 's/"//g' | base64 --decode)
sed -e "s/ES_PASSWORD/${ES_PASSWORD}/g" logstash.yaml >/tmp/logstash.yaml
kubectl apply -f /tmp/logstash.yaml




