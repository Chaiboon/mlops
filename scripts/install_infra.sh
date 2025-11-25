#!/bin/bash
set -e # Stop execution if any command fails

echo "🚀 Starting MLOps Platform Installation..."

echo "🏗️  Creating Kind Cluster..."
if ! kind get clusters | grep -q "kind"; then
  kind create cluster
  echo "✅ Cluster created successfully."
else
  echo "⚠️  Cluster 'kind' already exists. Skipping creation."
fi


echo "📦 Installing Cert Manager v1.19.1..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.1/cert-manager.yaml
kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=120s


echo "📝 Creating Cluster Issuer..."
kubectl apply -f manifests/infrastructure/cluster-issuer.yaml



echo "zzz Installing Gateway API CRDs v1.2.1..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml


echo "🚪 Installing Envoy Gateway v1.6.0..."
echo "   > Installing Envoy CRDs (Server-Side Apply)..."
kubectl apply --server-side -f https://github.com/envoyproxy/gateway/releases/download/v1.6.0/envoy-gateway-crds.yaml

echo "   > Installing Envoy Controller..."
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.6.0 \
  -n envoy-gateway-system \
  --create-namespace \
  --skip-crds \
  --wait


echo "🧠 Installing KServe v0.15.0..."
kubectl create namespace kserve --dry-run=client -o yaml | kubectl apply -f -

helm install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd --version v0.15.0 -n kserve --wait

echo "   > Attempting KServe Controller installation..."

if ! helm install kserve oci://ghcr.io/kserve/charts/kserve --version v0.15.0 \
  -n kserve \
  --set kserve.controller.deploymentMode=RawDeployment \
  --set kserve.controller.gateway.ingressGateway.enableGatewayApi=true \
  --set kserve.controller.gateway.ingressGateway.kserveGateway=kserve/kserve-ingress-gateway \
  --wait; then
  
  echo "⚠️  First attempt failed. Cleaning up 'Zombie Webhooks'..."
  
  kubectl delete validatingwebhookconfiguration \
    clusterservingruntime.serving.kserve.io \
    inferencegraph.serving.kserve.io \
    inferenceservice.serving.kserve.io \
    localmodelcache.serving.kserve.io \
    servingruntime.serving.kserve.io \
    trainedmodel.serving.kserve.io \
    --ignore-not-found
  
  echo "⏳ Waiting 100 seconds for Pods to stabilize..."
  sleep 100
  
  echo "🔄 Retrying with Helm Upgrade..."
  helm upgrade --install kserve oci://ghcr.io/kserve/charts/kserve --version v0.15.0 \
    -n kserve \
    --set kserve.controller.deploymentMode=RawDeployment \
    --set kserve.controller.gateway.ingressGateway.enableGatewayApi=true \
    --set kserve.controller.gateway.ingressGateway.kserveGateway=kserve/kserve-ingress-gateway \
    --wait
fi

kubectl apply -f manifests/models/secrets.yaml -n kserve

kubectl apply -f manifests/infrastructure/service-account.yaml

echo "🔧 Applying Your Custom Configurations..."
kubectl apply -f manifests/infrastructure/envoy-nodeport.yaml
kubectl apply -f manifests/infrastructure/gateway-class.yaml
kubectl apply -f manifests/infrastructure/minio.yaml
kubectl apply -f manifests/infrastructure/minio-init.yaml
kubectl apply -f manifests/infrastructure/mlflow.yaml

echo "✅ Installation Complete! Your MLOps Platform is ready."