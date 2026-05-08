#!/usr/bin/env bash
set -e

echo "================================="
echo " CKA Exam Environment Setup"
echo "================================="
echo ""

# Q1: 01-storage-pv-pvc / 01
echo "No additional setup required."
echo "The Killercoda playground cluster is ready to use."


# Q2: 02-storage-storageclass / 01
echo "Installing local-path provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
kubectl rollout status deployment/local-path-provisioner -n local-path-storage --timeout=90s
echo "local-path provisioner ready."


# Q3: 03-networking-services / 01
echo "Creating namespace and deployment for networking-services..."
kubectl create namespace web --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment web-app \
  --image=nginx:1.21 \
  --replicas=2 \
  --namespace=web \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label deployment web-app app=web-app -n web --overwrite
kubectl rollout status deployment/web-app -n web --timeout=90s
echo "Deployment 'web-app' is ready in namespace 'web'."


# Q4: 04-networking-ingress / 01
echo "Setting up ingress exercise environment..."
kubectl create namespace ingress-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment app-backend \
  --image=nginx:1.21 \
  --replicas=2 \
  --namespace=ingress-ns \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment app-backend \
  --name=app-svc \
  --port=80 \
  --target-port=80 \
  --namespace=ingress-ns \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout status deployment/app-backend -n ingress-ns --timeout=90s

# Install nginx ingress controller if not present
if ! kubectl get ingressclass nginx &>/dev/null; then
  echo "Installing nginx ingress controller..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/baremetal/deploy.yaml
  kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s
fi
echo "Setup complete. Service 'app-svc' ready in namespace 'ingress-ns'."


# Q5: 05-networking-gateway / 01
echo "Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

echo "Creating namespace and test service..."
kubectl create namespace gateway --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment app-backend \
  --image=nginx:1.21 \
  --namespace=gateway \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment app-backend \
  --name=app-svc \
  --port=80 \
  --namespace=gateway \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout status deployment/app-backend -n gateway --timeout=90s
echo "Setup complete."


# Q6: 06-networking-networkpolicy / 01
echo "Setting up network policy exercise..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace monitoring env=monitoring --overwrite

kubectl create deployment backend --image=nginx:1.21 --namespace=production --dry-run=client -o yaml | kubectl apply -f -
kubectl label deployment backend app=backend -n production --overwrite

kubectl create deployment frontend --image=nginx:1.21 --namespace=production --dry-run=client -o yaml | kubectl apply -f -
kubectl label deployment frontend app=frontend -n production --overwrite

kubectl create deployment monitor --image=nginx:1.21 --namespace=monitoring --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout status deployment/backend -n production --timeout=90s
kubectl rollout status deployment/frontend -n production --timeout=90s
echo "Setup complete."


# Q7: 07-networking-cni / 01
echo "No additional setup required."
echo "Using the existing cluster CNI configuration."


# Q8: 08-workloads-deployments / 01
echo "Creating namespace 'app'..."
kubectl create namespace app --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace ready."


# Q9: 09-workloads-sidecar / 01
echo "Setting up sidecar exercise..."
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx:1.21
        command: ["sh", "-c", "mkdir -p /var/log/app && while true; do echo \"$(date) INFO request processed\" >> /var/log/app/app.log; sleep 2; done"]
EOF

kubectl rollout status deployment/webapp -n logging --timeout=90s
echo "Deployment 'webapp' is ready in namespace 'logging'."


# Q10: 10-workloads-resources / 01
echo "Setting up resources exercise..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment api-server \
  --image=nginx:1.21 \
  --replicas=2 \
  --namespace=production \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout status deployment/api-server -n production --timeout=90s
echo "Deployment 'api-server' ready in namespace 'production'."


# Q11: 11-workloads-hpa / 01
echo "Setting up HPA exercise..."
kubectl create namespace autoscale --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment web-api \
  --image=nginx:1.21 \
  --replicas=1 \
  --namespace=autoscale \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout status deployment/web-api -n autoscale --timeout=90s

# Install metrics-server if not present
if ! kubectl get deployment metrics-server -n kube-system &>/dev/null; then
  echo "Installing metrics-server..."
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  kubectl patch deployment metrics-server -n kube-system \
    --type=json \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
fi
echo "Setup complete."


# Q12: 12-workloads-scheduling / 01
echo "Verifying cluster nodes..."
kubectl get nodes
echo ""
echo "Note: this exercise uses 'node01'. Adjust the node name if your cluster uses a different name."
echo "Check available nodes with: kubectl get nodes"


# Q13: 13-workloads-priorityclass / 01
echo "No additional setup required for PriorityClass exercise."


# Q14: 14-cluster-rbac / 01
echo "Creating namespace 'ci'..."
kubectl create namespace ci --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace 'ci' ready."


# Q15: 15-cluster-crd / 01
echo "No additional setup required."
echo "You will install cert-manager as part of the exercise."


# Q16: 16-cluster-etcd / 01
echo "============================================================"
echo "  WARNING: This setup BREAKS the kube-apiserver."
echo "  Only run this if you are prepared to fix it immediately."
echo "============================================================"
echo ""
read -r -p "Continue? (yes/no): " answer
if [[ "$answer" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

echo "Backing up kube-apiserver manifest..."
cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver-backup.yaml

echo "Injecting wrong etcd port (2379 -> 1234)..."
sed -i 's|etcd-servers=https://127.0.0.1:2379|etcd-servers=https://127.0.0.1:1234|' \
  /etc/kubernetes/manifests/kube-apiserver.yaml

echo "Waiting for kube-apiserver to fail..."
sleep 10
echo "Done. kube-apiserver is now misconfigured. Fix it!"
echo "Backup: /tmp/kube-apiserver-backup.yaml"


# Q17: 17-cluster-helm / 01
echo "Checking Helm installation..."
if ! command -v helm &>/dev/null; then
  echo "Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
helm version
echo "Helm is ready."


# Q18: 18-cluster-tls / 01
echo "No additional setup required."
echo "You will edit /etc/kubernetes/manifests/kube-apiserver.yaml directly."

