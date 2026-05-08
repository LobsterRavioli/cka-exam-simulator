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
