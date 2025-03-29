loadbalancer = $(kubectl get ingress -A | grep argocd | awk '{print $4}' | tail -1)
echo $loadbalancer

while [ true ];
do
   nslookup  $loadbalancer
   if [ $? eq 0 ]; then
      echo "Load balancer not exists"
      break;
   fi
   echo "Please wait until load balancer is active"
done

sleep10

while [ true ];
do
  argocd admin initial-password -n argocd | head -1
done

sleep 2

argocd login $( kubectl get ingress -A | grep argocd | awk '{print $4}' | tail -1)  --username admin --password $(argocd admin initial-password -n argocd | head -1) --insecure --skip-test-tls --grpc-web

for app in frontend catalogue user cart shipping payment; do
argocd app create {{app}} --repo https://github.com/devps23/roboshop-helm.git --path chart --dest-server https://kubernetes.default.svc --dest-namespace default.svc --grpc-web --values values/{{app}}.yaml

argocd app sync {{app}}
done