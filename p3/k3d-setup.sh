#!/usr/bin/env bash
set -euo pipefail

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

CLUSTER_NAME="mycluster"

APP_MANIFEST="argocd/playground-app.yaml"
ARGOCD_NS="argocd"
PORT=8080

echo "==> Creating k3d cluster: $CLUSTER_NAME"
# Create cluster if it doesn't exist
if ! k3d cluster list | grep -q "^$CLUSTER_NAME"; then
    # Expose port 8888 on the host to the cluster LoadBalancer
    k3d cluster create "$CLUSTER_NAME" --servers 1 --agents 2 --port "8888:8888@loadbalancer"
else
    echo "Cluster $CLUSTER_NAME already exists. Skipping creation."
fi

echo -e "${YELLOW}==> Setting up kubeconfig for k3d cluster...${NC}"
mkdir -p ~/.kube
k3d kubeconfig get "$CLUSTER_NAME" > ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

echo "==> Creating namespaces"
for ns in dev argocd; do
    if ! kubectl get namespace "$ns" >/dev/null 2>&1; then
        kubectl create namespace "$ns"
        echo "Namespace '$ns' created."
    else
        echo "Namespace '$ns' already exists. Skipping."
    fi
done

echo "==> Installing Argo CD in namespace 'argocd'"
if ! kubectl get deployment -n argocd argocd-server >/dev/null 2>&1; then
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
else
    echo "Argo CD is already installed. Skipping."
fi

echo "==> Applying Argo CD Application manifest..."
kubectl apply -f "$APP_MANIFEST" -n "$ARGOCD_NS"

echo "==> Retrieving Argo CD admin password..."
ADMIN_PASSWORD=$(kubectl -n "$ARGOCD_NS" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD admin password: $ADMIN_PASSWORD"

echo "==> Port-forwarding Argo CD server on https://localhost:$PORT ..."
echo "Press Ctrl+C to stop port-forwarding."
kubectl port-forward svc/argocd-server -n "$ARGOCD_NS" "$PORT":443
