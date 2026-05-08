echo "Creating namespace 'app'..."
kubectl create namespace app --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace ready."
