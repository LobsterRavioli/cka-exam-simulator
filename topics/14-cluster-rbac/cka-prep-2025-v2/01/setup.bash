echo "Creating namespace 'ci'..."
kubectl create namespace ci --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace 'ci' ready."
