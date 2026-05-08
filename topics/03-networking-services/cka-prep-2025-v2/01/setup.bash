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
