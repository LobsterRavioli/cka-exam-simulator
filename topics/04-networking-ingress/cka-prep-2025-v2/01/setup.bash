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
