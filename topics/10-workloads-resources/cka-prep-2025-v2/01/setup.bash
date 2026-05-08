echo "Setting up resources exercise..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment api-server \
  --image=nginx:1.21 \
  --replicas=2 \
  --namespace=production \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout status deployment/api-server -n production --timeout=90s
echo "Deployment 'api-server' ready in namespace 'production'."
