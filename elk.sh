# Install elk elastic,kibana logstash
* helm repo add elastic https://helm.elastic.co
* helm repo update
* kubectl create -f https://download.elastic.co/downloads/eck/2.16.1/crds.yaml
* kubectl apply -f https://download.elastic.co/downloads/eck/2.16.1/operator.yaml

# add add-on in eks cluster along with policy
# to expose a kibana application use kibana svc
# get  password for kibana
# kibana username: elastic
kubectl get secrets -n elastic-stack elasticsearch-es-elastic-user
ES_PASSWORD = kubectl get secrets -n elastic-stack elasticsearch-es-elastic-user -o json | jq '.data.elastic' | sed -e 's/"//g' | base64 --decode
# add ingress for kibana to expose application out
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kibana
  annotations:
      external-dns.alpha.kubernetes.io/hostname: kibana-dev.pdevops78.online
  namespace: elastic-stack
  labels:
    appName: kibana
    projectName: {{ .Chart.Name }}
spec:
  ingressClassName: nginx
  rules:
    - host: kibana-dev.pdevops78.online
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: es-kb-quickstart-eck-kibana-kb-http
                port:
                  number: 443

kubectl apply -f kibana-ingress.yaml
# once kibana login completes, send logs
#logstash
apiVersion: logstash.k8s.elastic.co/v1alpha1
kind: Logstash
metadata:
  name: quickstart
spec:
  count: 1
  elasticsearchRefs:
    - name: quickstart
      clusterName: qs
  version: 8.17.4
  pipelines:
    - pipeline.id: main
      config.string: |
        input {
          beats {
            port => 5044
          }
        }
        output {
          elasticsearch {
            hosts => [ "https://elasticsearch-es-http:9200" ]
            user => "elastic"
            password => "${ES_PASSWORD}"
            ssl_certificate_authorities => none
          }
        }
#        the above output.tf block is used to send this logstash logs to elasticsearch
  services:
    - name: beats
      service:
        spec:
          type: NodePort
          ports:
            - port: 5044
              name: "filebeat"
              protocol: TCP
              targetPort: 5044

kubectl apply -f logstash.yaml
------------------------------------------------------------------------
# filebeat collect the logs and send to logstash
# logstash didn't collect the logs directly
filebeat
========
apiVersion: beat.k8s.elastic.co/v1beta1
kind: Beat
metadata:
  name: filebeat
spec:
  type: filebeat
  version: 8.17.4
  elasticsearchRef:
    name: elasticsearch
  config:
    output.logstash:
        hosts: ["logstash-ls-beats:5044"]
#        // this filebeat sends to logstash, logstash-ls-beats this is a service
    filebeat.inputs:
    - type: container
      paths:
      - /var/log/containers/*.log
  daemonSet:
    podTemplate:
      spec:
        dnsPolicy: ClusterFirstWithHostNet
        hostNetwork: true
        securityContext:
          runAsUser: 0
        containers:
        - name: filebeat
          volumeMounts:
          - name: varlogcontainers
            mountPath: /var/log/containers
          - name: varlogpods
            mountPath: /var/log/pods
          - name: varlibdockercontainers
            mountPath: /var/lib/docker/containers
        volumes:
        - name: varlogcontainers
          hostPath:
            path: /var/log/containers
        - name: varlogpods
          hostPath:
            path: /var/log/pods
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers

kubectl apply -f filebeat.yaml

# to increase nodes automatically we can use autoscaler
* helm repo add autoscaler https://kubernetes.github.io/autoscaler
* helm upgrade -i node-autoscaler autoscaler/cluster-autoscaler --set 'autoDiscovery.clusterName'=dev-eks
# autoscaling is an aws service, to use eks cluster required permissions from aws service
# IAM policies
* add autoscaling policy: this policy is for to increase nodes
==============================================================
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": ["*"]
    }
  ]
}