#!/usr/bin/env bash

# Requires:
# kubectl
# helm
# codefresh cli
# curl

NAMESPACE="${1:-codefresh}"
NOW=$(date '+%Y%m%d%H%M%S')

echo "Creating Codefresh On-Premises Temp Directory"
mkdir -p codefresh-onprem-$NOW
cd codefresh-onprem-$NOW

echo "Gathering Codefresh On-Premises Information:"

# No filename was passed. Use default config file.
#test $CF_API_KEY && return $CF_API_KEY
if [ -z "$CFCONFIG" ]; then
  CFCONFIG='~/.cfconfig'
  echo "CFCONFIG env variable not found, using default config file ~/.cfconfig"
fi
if yq --help | grep -q  'https://github.com/mikefarah/yq/'; then
  #echo "yq command is present, continuing"
  #set +x
  ctx=$(cat $CFCONFIG | yq e ".current-context" -)
  API_TOKEN=$(cat $CFCONFIG | yq e ".contexts.$ctx.token" - | tr -d \")
  API_URL=$(cat $CFCONFIG | yq e ".contexts.$ctx.url" - | tr -d \")
  echo " - Using Codefresh URL $API_URL"
  echo "   ↳ Token of $ctx"
  
  echo " - Getting Codefresh On-Premises Accounts"
  curl --silent -k  \
  -X GET \
  -H "Authorization: $API_TOKEN" \
  "$API_URL/api/admin/accounts"  | jq '.[]' > onprem-accounts.json
  
  echo " - Getting Codefresh On-Premises Runtimes"
  curl --silent -k  \
  -X GET \
  -H "Authorization: $API_TOKEN" \
  "$API_URL/api/admin/runtime-environments"  | jq '.[]' > onprem-runtimes.json

else
  echo " - 💡 Compatible yq version is not found, please install it from https://github.com/mikefarah/yq/"
  echo "      account and runtime data will not be gathered, continuing"
fi

echo " - Release Version"
helm ls -n $NAMESPACE > onprem-release.txt
echo " - Nodes"
kubectl describe nodes > nodes.txt
echo " - StorageClass"
kubectl get storageclass -o yaml > storageClass.yaml
echo " - Deployments"
kubectl get deployments -n $NAMESPACE -o yaml > deployments.yaml
echo " - Daemonsets"
kubectl get daemonsets -n $NAMESPACE -o yaml > daemonsets.yaml
echo " - Services"
kubectl get service -n $NAMESPACE -o yaml > services.yaml
echo " - Events"
kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp > events.txt
echo " - Pods"
kubectl get pods -n $NAMESPACE -o wide > pod-list.txt

echo "Gathering Detailed Information in $NAMESPACE namepspace"

echo "Getting PVCs:"
kubectl get persistentvolumeclaim -n $NAMESPACE -o wide > persistentVolumeClaim-list.txt
for PVC in $(kubectl get persistentvolumeclaim -n $NAMESPACE --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p persistentVolumeClaim/$PVC
  kubectl get persistentvolumeclaim $PVC -n $NAMESPACE -o yaml > persistentVolumeClaim/$PVC/get.yaml
  kubectl describe persistentvolumeclaim $PVC -n $NAMESPACE > persistentVolumeClaim/$PVC/describe.txt
  echo " - $PVC"
  PV=$(kubectl get persistentvolumeclaim -n $NAMESPACE $PVC --no-headers -o custom-columns=":spec.volumeName")
  mkdir -p persistentVolume/$PV
  kubectl get persistentvolume $PV -o wide >> persistentVolume-list.txt
  kubectl get persistentvolume $PV -o yaml > persistentVolume/$PV/get.yaml
  kubectl describe persistentvolume $PV > persistentVolume/$PV/describe.txt
  echo "   ↳ PV: $PV"
done

echo "Getting Pods:"

#old labels
for POD in $(kubectl get pods -n $NAMESPACE -l 'app in (cf-cfapi, dind, cf-builder, cf-cf-broadcaster, cf-cfapi, cf-cfsign, cf-cfui, cf-chartmuseum, cf-charts-manager, cf-cluster-providers, cf-consul, cf-consul-ui, cf-context-manager, cronus, cf-gitops-dashboard-manager, cf-helm-repo-manager, cf-hermes, cf-ingress-controller, cf-ingress-http-backend, cf-k8s-monitor, cf-kube-integration, cf-nats, cf-nomios, cf-pipeline-manager, cf-postgresql, cf-rabbitmq, cf-redis, cf-registry, cf-runner, cf-runtime-environment-manager, cf-store, mongodb)' --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p pods/$POD
  echo " - $POD"
  kubectl get pods $POD -n $NAMESPACE -o yaml >> pods/$POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE >> pods/$POD/describe.txt
  echo "   ↳ Fetching $POD logs..."
  kubectl logs $POD -n $NAMESPACE --all-containers >> pods/$POD/logs.log
done

#new labels
for POD in $(kubectl get pods -n $NAMESPACE -l 'app.kubernetes.io/name in (argo-hub-platform, builder, cf-broadcaster, cf-broadcaster, cf-broadcaster, cfapi, cfsign, cfui, chartmuseum, charts-manager, cluster-providers, codefresh, consul, consul, context-manager, cronus, gitops-dashboard-manager, helm-repo-manager, hermes, ingress-nginx, internal-gateway, internal-gateway, internal-gateway, internal-gateway, internal-gateway, internal-gateway, k8s-monitor, kube-integration, mongodb, mongodb, nats, nats, nomios, pipeline-manager, platform-analytics, postgresql, postgresql, rabbitmq, rabbitmq, redis, redis, redis-platform-analytics, redis-platform-analytics, runner, runtime-environment-manager, system-etl-postgres, tasker-kubernetes)'  --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p pods/$POD
  echo " - $POD"
  kubectl get pods $POD -n $NAMESPACE -o yaml >> pods/$POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE >> pods/$POD/describe.txt
  echo "   ↳ Fetching $POD logs..."
  kubectl logs $POD -n $NAMESPACE --all-containers >> pods/$POD/logs.log
done

echo "Archiving Contents and cleaning up"
cd ..
tar -czf codefresh-onprem-$NOW.tar.gz codefresh-onprem-$NOW
rm -rf codefresh-onprem-$NOW

echo "🎉 New Tar Package: codefresh-onprem-$NOW.tar.gz"
echo "Please attach codefresh-onprem-$NOW.tar.gz to your support ticket"
