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
