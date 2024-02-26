#!/bin/bash

# Configure hostname and /etc/hosts
sudo hostnamectl set-hostname k8s-master-node1
echo "172.24.200.201 k8s-master-node1 master1" | sudo tee -a /etc/hosts
echo "172.24.200.205 k8s-worker-node1 worker1" | sudo tee -a /etc/hosts
echo "172.24.100.60 k8s-worker-node2 woker2" | sudo tee -a /etc/hosts

# Install dependencies
sudo yum install -y nano
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y yum-utils containerd.io && rm -I /etc/containerd/config.toml
sudo systemctl enable containerd && sudo systemctl start containerd

# Check containerd status
sudo systemctl status containerd

# Add Kubernetes repository
sudo tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install Kubernetes components
sudo yum install -y kubelet kubectl kubeadm

# Disable swap
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

# Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Configure sysctl settings
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# module br_netfilter
sudo modprobe br_netfilter
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Configure firewall cluster
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10251/tcp
sudo firewall-cmd --permanent --add-port=10252/tcp
sudo firewall-cmd --permanent --add-port=10255/tcp
sudo firewall-cmd --reload

# For Worker Nodes worker
# sudo firewall-cmd --permanent --add-port=10251/tcp
# sudo firewall-cmd --permanent --add-port=10255/tcp
# sudo firewall-cmd --reload

# Initialize Kubernetes cluster
sudo kubeadm init --pod-network-cidr=172.24.199.0/24

# Enable kubelet service
sudo systemctl enable kubelet && sudo systemctl status kubelet

# Create kubeconfig directory cluser
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Deploy Calico network plugin - cluster
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml -O
sudo kubectl apply -f calico.yaml

# Check cluster status
sudo kubectl get nodes
sudo kubectl get pods --all-namespaces

# Print join command for worker nodes master
sudo kubeadm token create --print-join-command

# join on worker
# kubeadm join 172.24.200.201:6443 --token jnb80l.jjp6td8jfaof0pct --discovery-token-ca-cert-hash sha256:20882a6b3ea7f38b3122e705452c8566cada55077ccf35e0770a993eb745f6c3

