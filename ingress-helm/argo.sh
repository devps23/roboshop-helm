#loadbalancer = $(kubectl get ingress -A | grep argocd | awk '{print $4}' | tail -1)
#echo $loadbalancer
#
#while [ true ];
#do
#   nslookup  $loadbalancer
#   if [ $? -eq 0 ]; then
#      echo "Load balancer not exists"
#      break;
#   fi
#   echo "Please wait until load balancer is active"
#done
#
#sleep10
#
#  argocdpass = argocd admin initial-password -n argocd | head -1
#while [ true ];
#do
#  echo $argocdpass
#  if [ $? -eq 0 ]; then
#    echo "argocd password not exists "
#    break;
#  fi
#done
#
#sleep 2

argocd login $( kubectl get ingress -A | grep argocd | awk '{print $4}' | tail -1)  --username admin --password $(argocd admin initial-password -n argocd | head -1) --insecure --skip-test-tls --grpc-web

for app in frontend catalogue user cart shipping payment; do
argocd app create ${app} --repo https://github.com/devps23/roboshop-helm.git --path chart --dest-server https://kubernetes.default.svc --dest-namespace default.svc --grpc-web --values values/${app}.yaml

argocd app sync ${app}

done

## add repo for prometheus
#helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
## add repo update
#helm repo update
#
#helm upgrade -i pstack prometheus-community/kube-prometheus-stack -f pstack-dev.yaml

# grafana default username / password - admin / prom-operator
#kubectl create -f https://download.elastic.co/downloads/eck/2.13.0/crds.yaml
#kubectl apply -f https://download.elastic.co/downloads/eck/2.13.0/operator.yaml
#helm upgrade -i elk elastic/eck-stack -n elastic-stack --create-namespace
#
#ES_PASSWORD=$(kubectl get secrets -n elastic-stack elasticsearch-es-elastic-user -o json | jq '.data.elastic' | sed -e 's/"//g' | base64 --decode)
#sed -e "s/ES_PASSWORD/${ES_PASSWORD}/" eck.yaml >/tmp/eck.yaml
#kubectl apply -f /tmp/eck.yaml
#
#helm repo add elastic https://helm.elastic.co
#helm upgrade -i filebeat elastic/filebeat -f filebeat.yml
#
#helm repo add autoscaler https://kubernetes.github.io/autoscaler
#helm upgrade -i node-autoscaler autoscaler/cluster-autoscaler --set 'autoDiscovery.clusterName'=dev-eks
#
#kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
#
#
### End
#echo
#echo
#echo
#echo "ArgoCD Password : $(argocd admin initial-password -n argocd | head -1)"
#echo "Grafana Username / Password : admin  / prom-operator"
#echo "Elastic Username / Password : elastic  / $(kubectl get secrets -n elastic-stack elasticsearch-es-elastic-user -o json | jq '.data.elastic' | sed -e 's/"//g' | base64 --decode)"
#
