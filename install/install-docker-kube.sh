#!/bin/bash

# Install dependencies
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y yum-utils containerd.io && rm -I /etc/containerd/config.toml
sudo systemctl enable containerd && sudo systemctl start containerd

# Check containerd status
sudo systemctl status containerd

# Install nano text editor
sudo yum install -y nano

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

# Configure hostname and /etc/hosts
sudo hostnamectl set-hostname k8s-master-node1
echo "127.0.0.1 localhost k8s-master-node1" | sudo tee -a /etc/hosts

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
echo '1' > /proc/sys/net/ipv4/ip_forward
sudo sysctl --system

# Configure firewall
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10251/tcp
sudo firewall-cmd --permanent --add-port=10252/tcp
sudo firewall-cmd --permanent --add-port=10255/tcp
sudo firewall-cmd --reload

# For Worker Nodes
# sudo firewall-cmd --permanent --add-port=10251/tcp
# sudo firewall-cmd --permanent --add-port=10255/tcp
# sudo firewall-cmd --reload

# Initialize Kubernetes cluster
sudo kubeadm init --pod-network-cidr=172.24.199.0/24

# Enable kubelet service
sudo systemctl enable kubelet
sudo systemctl start kubelet

# Create kubeconfig directory
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Deploy Calico network plugin
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml -O
sudo kubectl apply -f calico.yaml

# Check cluster status
sudo kubectl get nodes
sudo kubectl get pods --all-namespaces

# Print join command for worker nodes
sudo kubeadm token create --print-join-command
