# CKA Practice Exam — cka-prep-2025-v2

**Generated:** Ven  8 Mag 2026 12:15:11 CEST
**Type:** cka-prep-2025-v2
**Seed:** none (random)

> Run `bash setup.bash` on Killercoda before starting.

---

## Question 1 — 01-storage-pv-pvc

**Domain:** Storage (10%)  
**Variation:** 01

**Task** (4%)

Perform the following storage tasks:

1. Create a **PersistentVolume** named `mariadb-pv`:
   - Capacity: `1Gi`
   - AccessMode: `ReadWriteOnce`
   - StorageClassName: `manual`
   - ReclaimPolicy: `Retain`
   - HostPath: `/mnt/mariadb-data`

2. Create the namespace `mariadb`.

3. Create a **PersistentVolumeClaim** named `mariadb-pvc` in namespace `mariadb`:
   - StorageClassName: `manual`
   - AccessMode: `ReadWriteOnce`
   - Requests: `500Mi`

4. Deploy a **Pod** named `mariadb` in namespace `mariadb`:
   - Image: `mariadb:10.6`
   - Env: `MYSQL_ROOT_PASSWORD=secret`
   - Mount `mariadb-pvc` at `/var/lib/mysql`

**Verify:** the PVC status is `Bound` and the Pod is `Running`.

<details>
<summary>Solution</summary>

```bash
kubectl create namespace mariadb

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
spec:
  capacity:
    storage: 1Gi
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/mariadb-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc
  namespace: mariadb
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: manual
  resources:
    requests:
      storage: 500Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: mariadb
  namespace: mariadb
spec:
  containers:
  - name: mariadb
    image: mariadb:10.6
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: "secret"
    volumeMounts:
    - name: data
      mountPath: /var/lib/mysql
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: mariadb-pvc
EOF

# Verify
kubectl get pv mariadb-pv
kubectl get pvc -n mariadb
kubectl get pod mariadb -n mariadb
```

</details>

---

## Question 2 — 02-storage-storageclass

**Domain:** Storage (10%)  
**Variation:** 01

**Task** (4%)

1. Create a **StorageClass** named `fast-local`:
   - Provisioner: `rancher.io/local-path`
   - VolumeBindingMode: `WaitForFirstConsumer`
   - ReclaimPolicy: `Delete`

2. Create a **PersistentVolumeClaim** named `fast-pvc` in namespace `default`:
   - StorageClassName: `fast-local`
   - AccessMode: `ReadWriteOnce`
   - Requests: `1Gi`

3. Create a **Pod** named `pvc-consumer` in namespace `default`:
   - Image: `nginx:1.21`
   - Mount `fast-pvc` at `/usr/share/nginx/html`

**Verify:** after the Pod is scheduled, the PVC transitions to `Bound`.

<details>
<summary>Solution</summary>

```bash
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-local
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fast-pvc
  namespace: default
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: fast-local
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: pvc-consumer
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    volumeMounts:
    - name: web
      mountPath: /usr/share/nginx/html
  volumes:
  - name: web
    persistentVolumeClaim:
      claimName: fast-pvc
EOF

# Wait for Pod to be scheduled, then verify PVC is Bound
kubectl wait pod/pvc-consumer --for=condition=Ready --timeout=60s
kubectl get pvc fast-pvc
```

</details>

---

## Question 3 — 03-networking-services

**Domain:** Services & Networking (20%)  
**Variation:** 01

**Task** (4%)

A Deployment named `web-app` already exists in namespace `web`.

1. Create a **NodePort Service** named `web-svc` in namespace `web`:
   - Selector: `app=web-app`
   - Port: `80` → targetPort: `80`
   - NodePort: `30080`
   - Protocol: TCP

2. Verify connectivity: from the control-plane node, run:
   ```
   curl http://localhost:30080
   ```
   It should return the nginx welcome page.

<details>
<summary>Solution</summary>

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: web
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
EOF

# Verify
kubectl get svc web-svc -n web
curl http://localhost:30080
```

</details>

---

## Question 4 — 04-networking-ingress

**Domain:** Services & Networking (20%)  
**Variation:** 01

**Task** (4%)

A Deployment and ClusterIP Service named `app-svc` (port 80) exist in namespace `ingress-ns`.

1. Create an **Ingress** resource named `app-ingress` in namespace `ingress-ns`:
   - Host: `app.local`
   - Path: `/app` (pathType: `Prefix`)
   - Backend: `app-svc:80`
   - IngressClassName: `nginx`

2. Add `app.local` to `/etc/hosts` on the control-plane node pointing to `127.0.0.1`.

3. Verify: `curl http://app.local/app` returns a response from nginx.

<details>
<summary>Solution</summary>

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: ingress-ns
spec:
  ingressClassName: nginx
  rules:
  - host: app.local
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: app-svc
            port:
              number: 80
EOF

# Add /etc/hosts entry
echo "127.0.0.1 app.local" | sudo tee -a /etc/hosts

# Verify
kubectl get ingress app-ingress -n ingress-ns
curl -H "Host: app.local" http://app.local/app
```

</details>

---

## Question 5 — 05-networking-gateway

**Domain:** Services & Networking (20%)  
**Variation:** 01

**Task** (5%)

A Service named `app-svc` (port 80) exists in namespace `gateway`.
The Gateway API CRDs are already installed.

1. Create a **Gateway** named `main-gateway` in namespace `gateway`:
   - GatewayClassName: `nginx`
   - Listener: port `80`, protocol `HTTP`

2. Create an **HTTPRoute** named `app-route` in namespace `gateway`:
   - Attach to gateway `main-gateway`
   - Match hostname: `route.local`
   - Forward all traffic to `app-svc:80`

3. Add `route.local` to `/etc/hosts` pointing to `127.0.0.1`.

4. Verify: `curl -H "Host: route.local" http://route.local` returns a response.

<details>
<summary>Solution</summary>

```bash
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-route
  namespace: gateway
spec:
  parentRefs:
  - name: main-gateway
  hostnames:
  - "route.local"
  rules:
  - backendRefs:
    - name: app-svc
      port: 80
EOF

echo "127.0.0.1 route.local" | sudo tee -a /etc/hosts

kubectl get gateway main-gateway -n gateway
kubectl get httproute app-route -n gateway
curl -H "Host: route.local" http://route.local
```

</details>

---

## Question 6 — 06-networking-networkpolicy

**Domain:** Services & Networking (20%)  
**Variation:** 01

**Task** (6%)

Resources already exist in namespaces `production` and `monitoring`.

Create a **NetworkPolicy** named `backend-policy` in namespace `production` that:

1. Applies to pods with label `app=backend`
2. **Allows ingress** from pods with label `app=frontend` **in the same namespace** on any port
3. **Allows ingress** from any pod **in namespace `monitoring`** (label `env=monitoring`) on port `5432`
4. **Denies all other ingress** traffic

Do NOT modify any existing Deployments.

**Verify:** use `kubectl exec` to test connectivity between pods.

<details>
<summary>Solution</summary>

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
  - from:
    - namespaceSelector:
        matchLabels:
          env: monitoring
    ports:
    - protocol: TCP
      port: 5432
EOF

# Verify policy is applied
kubectl get networkpolicy backend-policy -n production

# Test from frontend pod (should succeed)
FRONTEND_POD=$(kubectl get pod -n production -l app=frontend -o jsonpath='{.items[0].metadata.name}')
BACKEND_IP=$(kubectl get pod -n production -l app=backend -o jsonpath='{.items[0].status.podIP}')
kubectl exec -n production "$FRONTEND_POD" -- curl -s --max-time 3 "http://$BACKEND_IP" && echo "OK: frontend can reach backend"
```

</details>

---

## Question 7 — 07-networking-cni

**Domain:** Services & Networking (20%)  
**Variation:** 01

**Task** (4%)

1. Identify which CNI plugin is installed on this cluster:
   - Check `/etc/cni/net.d/` on the control-plane node
   - Check running pods in `kube-system`

2. Create namespace `net-test`.

3. Deploy two pods in `net-test`:
   - `server`: image `nginx:1.21`, label `app=server`
   - `client`: image `busybox:1.35`, command `["sleep", "3600"]`

4. Expose `server` as a ClusterIP Service named `server-svc` on port `80`.

5. From the `client` pod, verify:
   - DNS resolution: `nslookup server-svc.net-test.svc.cluster.local`
   - HTTP connectivity: `wget -qO- http://server-svc.net-test.svc.cluster.local`

Write the CNI plugin name to `/tmp/cni-plugin.txt`.

<details>
<summary>Solution</summary>

```bash
# Identify CNI plugin
ls /etc/cni/net.d/
kubectl get pods -n kube-system | grep -E 'calico|flannel|weave|cilium'

# Write CNI name (adjust based on what you find)
echo "flannel" > /tmp/cni-plugin.txt  # example

# Create resources
kubectl create namespace net-test

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: server
  namespace: net-test
  labels:
    app: server
spec:
  containers:
  - name: nginx
    image: nginx:1.21
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  namespace: net-test
spec:
  containers:
  - name: busybox
    image: busybox:1.35
    command: ["sleep", "3600"]
EOF

kubectl expose pod server --name=server-svc --port=80 -n net-test

kubectl wait pod/server pod/client -n net-test --for=condition=Ready --timeout=60s

# Verify connectivity
kubectl exec -n net-test client -- nslookup server-svc.net-test.svc.cluster.local
kubectl exec -n net-test client -- wget -qO- http://server-svc.net-test.svc.cluster.local
```

</details>

---

## Question 8 — 08-workloads-deployments

**Domain:** Workloads & Scheduling (15%)  
**Variation:** 01

**Task** (4%)

1. Create a **Deployment** named `nginx-deploy` in namespace `app`:
   - Image: `nginx:1.21`
   - Replicas: `3`
   - Label: `app=nginx`
   - Strategy: `RollingUpdate` with `maxSurge=1`, `maxUnavailable=0`

2. Update the image to `nginx:1.25` and wait for the rollout to complete.

3. Annotate the rollout with: `kubectl.kubernetes.io/change-cause="upgrade to 1.25"`

4. If the rollout fails, roll back to the previous version.

5. Write the current image version to `/tmp/nginx-version.txt`.

<details>
<summary>Solution</summary>

```bash
# Create deployment
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
  namespace: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
EOF

kubectl rollout status deployment/nginx-deploy -n app

# Update image
kubectl set image deployment/nginx-deploy nginx=nginx:1.25 -n app
kubectl annotate deployment/nginx-deploy kubernetes.io/change-cause="upgrade to 1.25" -n app
kubectl rollout status deployment/nginx-deploy -n app --timeout=60s

# Rollback if needed
# kubectl rollout undo deployment/nginx-deploy -n app

# Record current version
kubectl get deployment nginx-deploy -n app -o jsonpath='{.spec.template.spec.containers[0].image}' > /tmp/nginx-version.txt
cat /tmp/nginx-version.txt
```

</details>

---

## Question 9 — 09-workloads-sidecar

**Domain:** Workloads & Scheduling (15%)  
**Variation:** 01

**Task** (5%)

A Deployment named `webapp` exists in namespace `logging`.
The main container writes logs to `/var/log/app/app.log`.

Add a **sidecar container** to the Deployment:
- Name: `log-agent`
- Image: `busybox:1.35`
- Command: `["sh", "-c", "tail -f /var/log/app/app.log"]`
- Mount a shared `emptyDir` volume at `/var/log/app`

Also mount the same `emptyDir` volume in the main container at `/var/log/app`.

**Verify:** check that `log-agent` is running and tailing the log file:
```
kubectl logs -n logging <pod-name> -c log-agent
```

<details>
<summary>Solution</summary>

```bash
# Edit the deployment to add sidecar + shared volume
kubectl patch deployment webapp -n logging --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes",
    "value": [{"name": "logs", "emptyDir": {}}]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts",
    "value": [{"name": "logs", "mountPath": "/var/log/app"}]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/-",
    "value": {
      "name": "log-agent",
      "image": "busybox:1.35",
      "command": ["sh", "-c", "tail -f /var/log/app/app.log"],
      "volumeMounts": [{"name": "logs", "mountPath": "/var/log/app"}]
    }
  }
]'

kubectl rollout status deployment/webapp -n logging

# Verify sidecar logs
POD=$(kubectl get pod -n logging -l app=webapp -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n logging "$POD" -c log-agent
```

</details>

---

## Question 10 — 10-workloads-resources

**Domain:** Workloads & Scheduling (15%)  
**Variation:** 01

**Task** (4%)

A Deployment named `api-server` exists in namespace `production`.

1. Update all containers in `api-server` to set:
   - Requests: `cpu=100m`, `memory=128Mi`
   - Limits: `cpu=500m`, `memory=256Mi`

2. Create a **LimitRange** named `default-limits` in namespace `production`:
   - Default CPU request: `50m`
   - Default memory request: `64Mi`
   - Default CPU limit: `200m`
   - Default memory limit: `128Mi`

3. Verify: `kubectl describe limitrange default-limits -n production`

<details>
<summary>Solution</summary>

```bash
# Set resource requests and limits
kubectl set resources deployment api-server -n production \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=256Mi

kubectl rollout status deployment/api-server -n production

# Create LimitRange
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
  - type: Container
    default:
      cpu: 200m
      memory: 128Mi
    defaultRequest:
      cpu: 50m
      memory: 64Mi
EOF

kubectl describe limitrange default-limits -n production
```

</details>

---

## Question 11 — 11-workloads-hpa

**Domain:** Workloads & Scheduling (15%)  
**Variation:** 01

**Task** (5%)

A Deployment named `web-api` exists in namespace `autoscale`.

1. Ensure the `web-api` Deployment has CPU resource requests set:
   - Request: `cpu=100m`

2. Create a **HorizontalPodAutoscaler** named `web-api-hpa` for `web-api`:
   - Min replicas: `2`
   - Max replicas: `10`
   - Target CPU utilisation: `50%`

3. Verify: `kubectl get hpa web-api-hpa -n autoscale`

4. Write the current replica count to `/tmp/hpa-replicas.txt`.

<details>
<summary>Solution</summary>

```bash
# Ensure CPU requests are set
kubectl set resources deployment web-api -n autoscale --requests=cpu=100m

# Create HPA
kubectl autoscale deployment web-api \
  --name=web-api-hpa \
  --min=2 \
  --max=10 \
  --cpu-percent=50 \
  -n autoscale

# Verify
kubectl get hpa web-api-hpa -n autoscale

# Write replica count
kubectl get deployment web-api -n autoscale -o jsonpath='{.spec.replicas}' > /tmp/hpa-replicas.txt
cat /tmp/hpa-replicas.txt
```

</details>

---

## Question 12 — 12-workloads-scheduling

**Domain:** Workloads & Scheduling (15%)  
**Variation:** 01

**Task** (5%)

1. Add a **taint** to `node01`:
   - Key: `dedicated`, Value: `gpu`, Effect: `NoSchedule`

2. Label `node01` with `hardware=gpu`.

3. Create a **Pod** named `gpu-pod` in namespace `default`:
   - Image: `nginx:1.21`
   - Add a **toleration** for the taint: `dedicated=gpu:NoSchedule`
   - Add **node affinity** (requiredDuringSchedulingIgnoredDuringExecution) requiring `hardware=gpu`

4. Verify `gpu-pod` is scheduled on `node01`.

5. Create a second Pod named `regular-pod` (image `nginx:1.21`) with **no toleration** and verify it does **not** schedule on `node01`.

<details>
<summary>Solution</summary>

```bash
# Taint and label the node
kubectl taint node node01 dedicated=gpu:NoSchedule
kubectl label node node01 hardware=gpu

# Create gpu-pod with toleration and affinity
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
  namespace: default
spec:
  tolerations:
  - key: "dedicated"
    value: "gpu"
    effect: "NoSchedule"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: hardware
            operator: In
            values: [gpu]
  containers:
  - name: nginx
    image: nginx:1.21
EOF

# Create regular-pod (no toleration)
kubectl run regular-pod --image=nginx:1.21

kubectl wait pod/gpu-pod --for=condition=Ready --timeout=60s

# Verify scheduling
kubectl get pod gpu-pod -o wide
kubectl get pod regular-pod -o wide
```

</details>

---

## Question 13 — 13-workloads-priorityclass

**Domain:** Workloads & Scheduling (15%)  
**Variation:** 01

**Task** (3%)

1. Create a **PriorityClass** named `high-priority`:
   - Value: `1000000`
   - GlobalDefault: `false`
   - Description: `"Used for critical production workloads"`

2. Create a **PriorityClass** named `low-priority`:
   - Value: `100`
   - GlobalDefault: `false`

3. Create a Pod named `critical-pod` in namespace `default`:
   - Image: `nginx:1.21`
   - PriorityClassName: `high-priority`

4. Create a Pod named `background-pod` in namespace `default`:
   - Image: `busybox:1.35`, command: `["sleep", "3600"]`
   - PriorityClassName: `low-priority`

5. Verify both pods are Running and have the correct priority.

<details>
<summary>Solution</summary>

```bash
kubectl apply -f - <<'EOF'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "Used for critical production workloads"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
globalDefault: false
---
apiVersion: v1
kind: Pod
metadata:
  name: critical-pod
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx:1.21
---
apiVersion: v1
kind: Pod
metadata:
  name: background-pod
spec:
  priorityClassName: low-priority
  containers:
  - name: busybox
    image: busybox:1.35
    command: ["sleep", "3600"]
EOF

kubectl wait pod/critical-pod pod/background-pod --for=condition=Ready --timeout=60s
kubectl get pod critical-pod background-pod -o custom-columns='NAME:.metadata.name,PRIORITY:.spec.priority,STATUS:.status.phase'
```

</details>

---

## Question 14 — 14-cluster-rbac

**Domain:** Cluster Architecture (25%)  
**Variation:** 01

**Task** (6%)

1. Create the namespace `ci`.

2. Create a **ServiceAccount** named `ci-runner` in namespace `ci`.

3. Create a **Role** named `deployer` in namespace `ci` with permissions:
   - `get`, `list`, `watch` on `pods`
   - `create`, `update`, `patch`, `get`, `list` on `deployments`

4. Create a **RoleBinding** named `ci-deployer` in namespace `ci`:
   - Bind `ci-runner` ServiceAccount to the `deployer` Role

5. Verify with:
   ```
   kubectl auth can-i create deployments --as=system:serviceaccount:ci:ci-runner -n ci
   kubectl auth can-i delete deployments --as=system:serviceaccount:ci:ci-runner -n ci
   ```
   First should return `yes`, second `no`.

<details>
<summary>Solution</summary>

```bash
kubectl create serviceaccount ci-runner -n ci

kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: ci
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["create", "update", "patch", "get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-deployer
  namespace: ci
subjects:
- kind: ServiceAccount
  name: ci-runner
  namespace: ci
roleRef:
  kind: Role
  name: deployer
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl auth can-i create deployments --as=system:serviceaccount:ci:ci-runner -n ci
kubectl auth can-i delete deployments --as=system:serviceaccount:ci:ci-runner -n ci
```

</details>

---

## Question 15 — 15-cluster-crd

**Domain:** Cluster Architecture (25%)  
**Variation:** 01

**Task** (5%)

1. Install **cert-manager** by applying its manifest:
   ```
   https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.yaml
   ```

2. Wait for all cert-manager pods in namespace `cert-manager` to be `Running`.

3. Create a **ClusterIssuer** named `selfsigned-issuer`:
   - Type: `selfSigned`

4. Create a **Certificate** named `test-cert` in namespace `default`:
   - SecretName: `test-cert-tls`
   - IssuerRef: `selfsigned-issuer` (kind: ClusterIssuer)
   - DNSNames: `["example.local"]`
   - Duration: `2160h` (90 days)

5. Verify: `kubectl get certificate test-cert -n default` shows `READY=True`.

<details>
<summary>Solution</summary>

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.yaml

kubectl rollout status deployment/cert-manager -n cert-manager --timeout=120s
kubectl rollout status deployment/cert-manager-webhook -n cert-manager --timeout=120s
kubectl rollout status deployment/cert-manager-cainjector -n cert-manager --timeout=120s

kubectl apply -f - <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-cert
  namespace: default
spec:
  secretName: test-cert-tls
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  dnsNames:
  - example.local
  duration: 2160h
EOF

kubectl wait certificate/test-cert -n default --for=condition=Ready --timeout=60s
kubectl get certificate test-cert -n default
```

</details>

---

## Question 16 — 17-cluster-helm

**Domain:** Cluster Architecture (25%)  
**Variation:** 01

**Task** (5%)

Install **ArgoCD** using Helm with the following requirements:

1. Add the Helm repository:
   - Name: `argo`
   - URL: `https://argoproj.github.io/argo-helm`

2. Create the namespace `argocd`.

3. Install the chart with:
   - Chart: `argo/argo-cd`
   - Release name: `argocd`
   - Namespace: `argocd`
   - Flag: `--skip-crds` (do NOT install CRDs)
   - Set: `server.service.type=NodePort`

4. Wait for all pods in namespace `argocd` to be `Running`.

5. Write the ArgoCD server NodePort to `/tmp/argocd-port.txt`.

<details>
<summary>Solution</summary>

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

helm install argocd argo/argo-cd \
  --namespace argocd \
  --skip-crds \
  --set server.service.type=NodePort

kubectl rollout status deployment/argocd-server -n argocd --timeout=180s

kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}' \
  > /tmp/argocd-port.txt
cat /tmp/argocd-port.txt
```

</details>

---

## Question 17 — 18-cluster-tls

**Domain:** Cluster Architecture (25%)  
**Variation:** 01

**Task** (5%)

Configure the kube-apiserver to enforce a minimum TLS version.

1. Edit the static pod manifest at `/etc/kubernetes/manifests/kube-apiserver.yaml`.

2. Add the following flag to the `command` section:
   ```
   - --tls-min-version=VersionTLS13
   ```

3. Wait for the kube-apiserver to restart (kubelet detects the change automatically).

4. Verify the flag is active:
   ```
   kubectl get pod -n kube-system | grep apiserver
   ps aux | grep tls-min-version
   ```

5. Create a **ConfigMap** named `tls-config` in namespace `kube-system`:
   - Key `min-version`: `TLS1.3`
   - Key `configured-by`: `kube-apiserver-manifest`

<details>
<summary>Solution</summary>

```bash
# Backup before editing
cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver-backup.yaml

# Add the flag (insert after the first 'command:' block entry)
# Use vi or sed:
sed -i '/- kube-apiserver/a\    - --tls-min-version=VersionTLS13' \
  /etc/kubernetes/manifests/kube-apiserver.yaml

# Verify the flag was added
grep tls-min-version /etc/kubernetes/manifests/kube-apiserver.yaml

# Wait for apiserver restart
echo "Waiting for kube-apiserver to restart..."
sleep 20

# Confirm it's running
kubectl get pod -n kube-system | grep apiserver
ps aux | grep tls-min-version

# Create ConfigMap
kubectl create configmap tls-config \
  --from-literal=min-version=TLS1.3 \
  --from-literal=configured-by=kube-apiserver-manifest \
  -n kube-system
```

</details>

---


---

_Total: **17 / 18** questions included._
