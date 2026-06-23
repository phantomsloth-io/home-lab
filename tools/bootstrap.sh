#!/bin/bash
set -e

# Configuration
K3S_VERSION="v1.31.2+k3s1"
ARGOCD_VERSION="v2.13.1"

# Verify dependencies
for cmd in curl git; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Error: Required dependency '$cmd' is not installed." >&2
        exit 1
    fi
done

# Attempt to detect primary IP address of the local node
DETECTED_IP=""
if command -v ip >/dev/null 2>&1; then
    DETECTED_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
fi
if [ -z "$DETECTED_IP" ] && command -v hostname >/dev/null 2>&1; then
    DETECTED_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
DEFAULT_CONTROL_PLANE_IP=${DETECTED_IP:-"10.0.0.95"}

# Suggest an Argo CD LoadBalancer IP within the same subnet
SUBNET=$(echo "$DEFAULT_CONTROL_PLANE_IP" | grep -E -o '^[0-9]+\.[0-9]+\.[0-9]+\.')
DEFAULT_ARGOCD_LB_IP="${SUBNET}238"
if [ -z "$SUBNET" ]; then
    DEFAULT_ARGOCD_LB_IP="10.0.0.238"
fi

# Detect default Git repository URL
DEFAULT_REPO_URL="https://github.com/phantomsloth-io/home-lab.git"
DETECTED_REPO=$(git remote get-url origin 2>/dev/null || true)
DEFAULT_REPO_URL=${DETECTED_REPO:-$DEFAULT_REPO_URL}

# Interactive configuration prompts
echo "📝 Please configure your cluster parameters:"

read -p "Control Plane IP Address [$DEFAULT_CONTROL_PLANE_IP]: " input_control_plane_ip
CONTROL_PLANE_IP=${input_control_plane_ip:-$DEFAULT_CONTROL_PLANE_IP}

read -p "Argo CD LoadBalancer IP Address [$DEFAULT_ARGOCD_LB_IP]: " input_argocd_lb_ip
ARGOCD_LB_IP=${input_argocd_lb_ip:-$DEFAULT_ARGOCD_LB_IP}

read -p "Git Repository URL [$DEFAULT_REPO_URL]: " input_repo_url
REPO_URL=${input_repo_url:-$DEFAULT_REPO_URL}

echo "----------------------------------------"
echo "Configuration Summary:"
echo "  Control Plane IP: $CONTROL_PLANE_IP"
echo "  Argo CD LB IP:    $ARGOCD_LB_IP"
echo "  Repository URL:   $REPO_URL"
echo "----------------------------------------"
read -p "Proceed with these settings? (y/n) [y]: " confirm_settings
confirm_settings=${confirm_settings:-"y"}
if [ "$confirm_settings" != "y" ] && [ "$confirm_settings" != "Y" ]; then
    echo "❌ Bootstrap aborted by user."
    exit 0
fi

echo "🚀 Starting K3s + Argo CD Bootstrap..."

# 1. Install K3s (Control Plane)
if ! command -v k3s &> /dev/null; then
    echo "📦 Installing K3s..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION sh -s - server \
        --cluster-init \
        --tls-san=$CONTROL_PLANE_IP \
        --disable servicelb \
        --disable traefik \
        --write-kubeconfig-mode 644
else
    echo "✅ K3s already installed."
fi

# 2. Install Argo CD
echo "🐙 Installing Argo CD ($ARGOCD_VERSION)..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml

# 3. Configure Argo CD LoadBalancer
echo "🌐 Patching Argo CD Server to use LoadBalancer ($ARGOCD_LB_IP)..."
kubectl patch service argocd-server -n argocd --patch "{ \"spec\": { \"type\": \"LoadBalancer\", \"loadBalancerIP\": \"$ARGOCD_LB_IP\" } }"

# 4. Add Repository to Argo CD
# Note: For public repositories, Argo CD does not require authentication or manual repository registration.

echo "⏳ Waiting for Argo CD API server..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# 5. Apply the Root Application (App of Apps)
echo "🏗️  Applying Infrastructure Root App..."
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infra
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: HEAD
    path: argocd/infra
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo "✨ Bootstrap complete! Check your Argo CD UI at https://$ARGOCD_LB_IP"
echo "🔑 Initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
