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
