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
