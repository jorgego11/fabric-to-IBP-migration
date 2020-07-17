# Lessons Learned using this sample network

URL:   https://github.com/APGGroeiFabriek/PIVT

Make sure all the pre-reqs are installed

## Argo tweaks

This sample network uses Argo ( https://argoproj.github.io/ ) to deploy and update Fabric artifacts. 

On IBM Cloud we need to tell the Argo server to not expect docker as runtime because it uses containerd!
https://programming.vip/docs/easily-run-argo-workflow-in-a-serverless-kubernetes-cluster.html
Argo uses the docker executor api by default. In the serverless cluster, we need to switch to k8sapi to work normally.

```
# kubectl -n argo edit configmap workflow-controller-configmap
apiVersion: v1
kind: ConfigMap
...
data:
  config: |
    containerRuntimeExecutor: k8sapi
```



This below is required by Argo to be able to use kube API and do admin activities.  It will grant admin privileges to the default ServiceAccount in the namespace that the command is run from, so you will only be able to run Workflows in the namespace where the RoleBinding was made.
```
kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=hlf-kube:default --namespace=hlf-kube

# this should return yes if the command run successfully
kubectl auth can-i get pod --as=system:serviceaccount:hlf-kube:default          
``` 

## Installing Code 

Get the code from the branch docker-dind
```
git clone --branch docker-dind    https://github.com/APGGroeiFabriek/PIVT.git
```

Make sure your path can find Fabric CLI commands for the right version

Common commands you would run:
```
kubectl create namespace hlf-kafka
kubectl config set-context --current --namespace=hlf-kafka
# verify namespace
kubectl config view --minify | grep namespace:   
kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=hlf-kafka:default --namespace=hlf-kafka
# this should return  yes
kubectl auth can-i get pod --as=system:serviceaccount:hlf-kafka:default 
```

```
argo delete --all
./init.sh ./samples/scaled-kafka/ ./samples/chaincode/

#  note that we will install a release called hlf-kafka  in the namespace called hlf-kafka   :)
#  also note these instructions are using Helm v3 but the orifigal docs use v2, There is a slight diference in syntax

helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm dependency update ./hlf-kube/
 
# delete the deployed chart first
helm delete hlf-kafka

# create pods, services, volume claims, etc.
helm install  hlf-kafka   ./hlf-kube  -f samples/scaled-kafka/network.yaml -f samples/scaled-kafka/crypto-config.yaml -f samples/scaled-kafka/values.yaml --set peer.docker.dind.enabled=true 

# create channels  common,   private-karga-atlantis,  join peers to channels
helm template channel-flow/ -f samples/scaled-kafka/network.yaml -f samples/scaled-kafka/crypto-config.yaml | argo submit - --watch

# install chaincode
helm template chaincode-flow/ -f samples/scaled-kafka/network.yaml -f samples/scaled-kafka/crypto-config.yaml  | argo submit - --watch

```


Some useful commands to delete the dead pods left by running Argo

```
kubectl get pods -n <namespace>  --no-headers=true | awk '/hlf-channels-/{print $1}' | xargs  kubectl delete -n <namespace>  pod

kubectl get pods -n <namespace>  --no-headers=true | awk '/hlf-chaincodes/{print $1}' | xargs  kubectl delete -n <namespace>  pod
```
