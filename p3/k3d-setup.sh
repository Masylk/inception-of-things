#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="mycluster"

echo "==> Creating k3d cluster: $CLUSTER_NAME"
# Create cluster if it doesn't exist
if ! k3d cluster list | grep -q "^$CLUSTER_NAME"; then
    k3d cluster create "$CLUSTER_NAME" --servers 1 --agents 2
else
    echo "Cluster $CLUSTER_NAME already exists. Skipping creation."
fi

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

echo "==> Port-forward Argo CD UI (temporary)"
echo "You can run:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Then access UI at https://localhost:8080"

echo "==> Setup complete!"
