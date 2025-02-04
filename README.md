# **Project Documentation: Deploying Expensy App on AWS EKS**

## **1. Running Docker Containers Locally**

To test the application locally using Docker Compose:

```bash
# Start all services (backend, frontend, MongoDB, Redis) locally
docker-compose up --build

# If you want to run them in detached mode
docker-compose up --build -d

# To check the logs
docker-compose logs -f
```

After running this, visit:
- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:8706

You can test endpoints like `http://localhost:8706/api` for backend APIs.

## **2. Pushing Docker Images to Docker Hub**

### **Tag the images:**
```bash
docker tag expensy_backend krisssssssss/expensy_backend:latest
docker tag expensy_frontend krisssssssss/expensy_frontend:latest
```

### **Push the images:**
```bash
docker login
docker push krisssssssss/expensy_backend:latest
docker push krisssssssss/expensy_frontend:latest
```

---
## **3. Applying Terraform Configuration**

### **Production Environment:**
```bash
cd terraform/production
terraform init
terraform apply
```

### **Staging Environment:**
```bash
cd terraform/staging
terraform init
terraform apply
```

🚨 *Might be needed to comment the `eks_cluster` module at first and run `terraform apply` so that the VPC infrastructure is built. Then re-run it afterward.*

**Node groups must be created through AWS CLI.**

---
## **4. Connecting to the EKS Cluster**

### **Update kubeconfig:**
```bash
aws eks update-kubeconfig --region me-south-1 --name kris-production
```

### **Create Node Groups Using AWS CLI:**
```bash
aws eks create-nodegroup \
  --cluster-name kris-staging \
  --nodegroup-name kris-node-group \
  --subnets subnet-abc123 subnet-def456 subnet-ghi789 \ # Replace with private subnet IDs
  --node-role arn:aws:iam::438465169137:role/eks-node-role \ # Replace with IAM role ARN
  --scaling-config minSize=1,maxSize=4,desiredSize=2 \
  --instance-types t3.medium \
  --ami-type AL2_x86_64 \
  --disk-size 20 \
  --tags Environment=production
```

### **Verify Node Groups:**
```bash
aws eks describe-nodegroup --cluster-name kris-staging --nodegroup-name kris-node-group
kubectl get nodes
```

---
## **5. Deploying Kubernetes Manifests**

### **Apply ConfigMap and Secrets:**
```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
```

### **Deploy MongoDB, Redis, Backend, and Frontend:**
```bash
kubectl apply -f k8s/mongo-deployment.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
```

### **Verify Deployment:**
```bash
kubectl get services
kubectl get nodes
kubectl get pods
```

---
## **6. Testing the Deployed Application**

Copy the **EXTERNAL-IP** of the LoadBalancer and visit it in your browser:
```
http://<EXTERNAL-IP>:3000
```

---
## **7. Installing Ingress Controller**

### **Create namespace and install controllers:**
```bash
kubectl create namespace ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml -n ingress-nginx
```

### **Apply Ingress Rules:**
```bash
kubectl apply -f ingress.yaml
```

### **Verify Ingress Deployment:**
```bash
kubectl get ingress
```

---
## **8. Enabling EBS CSI Driver for Persistent Storage**
```bash
eksctl create addon --name aws-ebs-csi-driver --cluster kris-production
```

---
## **9. Setting Up Monitoring with Prometheus & Grafana**

### **Step 1: Install Helm (If Not Installed)**
```bash
helm version  # Check if installed
```
If Helm is missing, install it:
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

### **Step 2: Add Prometheus Helm Repo and Update**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### **Step 3: Create a Namespace for Prometheus**
```bash
kubectl create namespace prometheus
```

### **Step 4: Install Prometheus & Grafana**
```bash
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n prometheus
```

### **Step 5: Verify Installation**
```bash
kubectl get pods -n prometheus
kubectl get svc -n prometheus
```

### **Step 6: Expose Prometheus and Grafana**
```bash
kubectl patch svc prometheus-stack-kube-prom-prometheus -n prometheus -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc prometheus-stack-grafana -n prometheus -p '{"spec": {"type": "LoadBalancer"}}'
```

### **Step 7: Access Grafana Dashboard**
- Run `kubectl get svc -n prometheus` to get the **EXTERNAL-IP**.
- Open **Grafana in your browser:** `http://<EXTERNAL-IP>`
- Login using:
  - **Username:** `admin`
  - **Password:** `prom-operator`

### **Step 8: Import a Kubernetes Monitoring Dashboard**
1. **Go to Dashboards → Import**.
2. **Enter Dashboard ID:** `3119` _(Kubernetes Cluster Monitoring Dashboard)_.
3. Select **Prometheus** as the data source.
4. Click **Import**.

🎉 **Grafana is now monitoring your Kubernetes cluster!** 🚀

