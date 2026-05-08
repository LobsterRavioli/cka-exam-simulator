# DESTRUCTIVE
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
