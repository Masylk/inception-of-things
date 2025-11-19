#!/bin/bash
set -e

echo "=== Updating system ==="
apt-get update -y
apt-get upgrade -y

echo "=== Installing required base packages ==="
apt-get install -y curl sudo apt-transport-https ca-certificates gnupg

echo "=== Installing Docker (for building images) ==="
apt-get install -y docker.io
systemctl enable --now docker

echo "=== Installing K3s server ==="
export INSTALL_K3S_EXEC="server --node-ip 192.168.56.110"
export K3S_KUBECONFIG_MODE=644
curl -sfL https://get.k3s.io | sh -

echo "=== Waiting for K3s to start ==="
sleep 15

echo "=== Ensuring k3s-native Traefik is deployed ==="
TRAefik_MANIFEST=/var/lib/rancher/k3s/server/manifests/traefik.yaml
if [ ! -f "$TRAefik_MANIFEST" ]; then
echo "Downloading k3s-native Traefik manifest..."
curl -o $TRAefik_MANIFEST https://raw.githubusercontent.com/k3s-io/k3s/master/manifests/traefik.yaml
fi

echo "=== Waiting for Traefik to start ==="
sleep 15

echo "=== Building Docker images for apps and importing into K3s ==="
for app in app1 app2 app3; do
echo "Building Docker image for $app..."
cd /home/vagrant/apps/$app
docker build -t $app:latest .

echo "Saving Docker image and importing into K3s containerd..."
docker save $app:latest | k3s ctr images import -

done

echo "=== Applying Kubernetes Deployments and Services ==="
for app in app1 app2 app3; do
kubectl apply -f /home/vagrant/apps/$app/deployment.yaml
kubectl apply -f /home/vagrant/apps/$app/service.yaml
done

echo "=== Applying path-based Ingress ==="
kubectl apply -f /home/vagrant/apps/apps-ingress.yaml

# Add app hostnames to /etc/hosts if not already present
HOSTS_ENTRY="192.168.56.110 app1.com app2.com app3.com"
if ! grep -q "app1.com" /etc/hosts; then
  echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts
fi

echo "=== Setup finished successfully! ==="
