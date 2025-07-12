# Kubernetes Local Cluster: Ingress + MetalLB + Grafana + Prometheus

This guide sets up a local Kubernetes cluster (using `kubeadm`) and demonstrates how to expose services like **Grafana** and **Prometheus** using:

- Metrics Server
- Prometheus and Grafana via Helm
- NGINX Ingress Controller
- MetalLB for LoadBalancer support
- Local DNS (via /etc/hosts)
- Ingress resources for clean domain-based routing

---

## 🛠 Prerequisites

- A Kubernetes cluster with kubeadm (1 master + 2 workers)
- `kubectl` access configured
- `helm` installed
- `sudo` access on local machine to edit `/etc/hosts`

---

## 🚀 Step 1: Install helm

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

## 🚀 Step 2: Install Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
  (Optional) If you have TLS or certificate issues or are running on local clusters (like minikube, kubeadm), patch the deployment to allow insecure TLS:

```bash
kubectl -n kube-system edit deployment metrics-server
```

Find the container args and add:

```bash
- --kubelet-insecure-tls
- --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP
```

For example, args section becomes:

```bash
args:
  - --cert-dir=/tmp
  - --secure-port=4443
  - --kubelet-insecure-tls
  - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP
```

Save and exit.

Verify:

```bash
kubectl top nodes
```

## 🚀 Step 3: Install Prometheus and Grafana via Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Install Prometheus stack:

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

Grafana Password: Run this command to get the admin password

```bash
kubectl --namespace monitoring get secrets prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```

## 🚀 Step 4: Install MetalLB

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
```

Create `metallb-config.yaml`:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: my-ip-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.68.240-192.168.68.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
```

Apply it:

```bash
kubectl apply -f metallb-config.yaml
```

---

## 🌐 Step 5: Install Ingress-NGINX Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer
```

Check:

```bash
kubectl get svc -n ingress-nginx
```

---

## 🧭 Step 6: Configure Local DNS

Edit `/etc/hosts` on your local machine:

```bash
sudo nano /etc/hosts
```

Add:

```
192.168.68.240 grafana.local
192.168.68.240 prometheus.local
```

---

## 📈 Step 7: Expose Grafana and Prometheus

### Grafana Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
    - host: grafana.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 80
```

### Prometheus Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
    - host: prometheus.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-kube-prometheus-prometheus
                port:
                  number: 9090
```

Apply:

```bash
kubectl apply -f grafana-ingress.yaml
kubectl apply -f prometheus-ingress.yaml
```

---

## 🔍 Access Dashboards

- http://grafana.local
- http://prometheus.local

---

## 🧯 Troubleshooting

- Check service names, ports, and pod status
- Run `kubectl get endpoints <service>` to verify backing pods
- Make sure MetalLB IPs are not in use or part of DHCP
- Check Ingress logs for 503 errors or missing backends

---

Happy Monitoring! 🎉
