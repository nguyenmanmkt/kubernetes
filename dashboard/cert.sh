#!/bin/bash

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm version
# Tạo namespace cho cert-manager
kubectl create namespace cert-manager
# Cài đặt cert-manager CRDs
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.13.4/cert-manager.crds.yaml
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.13.4/cert-manager.yaml
# Kiểm tra trạng thái pods của cert-manager
kubectl get pods --namespace cert-manager

# ingress-nginx
# Tạo namespace cho nginx-ingress
kubectl create namespace nginx-ingress
#helm uninstall nginx-ingress --namespace nginx-ingress

# Cài đặt nginx-ingress-controller sử dụng Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace nginx-ingress

kubectl get pods --namespace nginx-ingress

# kubernetes-dashboard
# Tạo namespace cho Kubernetes Dashboard
kubectl create namespace kubernetes-dashboard

# Cài đặt cert-manager, nginx-ingress và Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v3.0.0-alpha0/aio/deploy/recommended.yaml

# Kiểm tra trạng thái pods của cert-manager, nginx-ingress và Kubernetes Dashboard
kubectl get pods --namespace cert-manager
kubectl get pods --namespace nginx-ingress
kubectl get pods --namespace kubernetes-dashboard



