#!/bin/bash

echo "unhold kubeadm, kubelet, kubectl"
sudo apt-mark hold kubelet kubeadm kubectl

echo "Stopping services..."
sudo systemctl stop kubelet
sudo systemctl stop containerd

echo "Resetting kubeadm..."
sudo kubeadm reset -f

echo "Unmounting kubelet volumes..."
sudo umount -l $(mount | grep '/var/lib/kubelet' | awk '{print $3}')

echo "Removing packages..."
sudo apt-get purge -y kubeadm kubelet kubectl containerd
sudo apt-get autoremove -y

echo "Deleting related files..."
sudo rm -rf /etc/kubernetes/ /var/lib/etcd/ /var/lib/kubelet/ \
             /var/lib/cni/ /etc/cni/ /opt/cni/ ~/.kube \
             /etc/systemd/system/kubelet.service.d \
             /etc/default/kubelet /etc/containerd/ \
             /var/lib/containerd/ /run/containerd/

echo "Resetting systemd..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl reset-failed

echo "Cleaning network..."
sudo ip link delete cni0 2>/dev/null
sudo ip link delete flannel.1 2>/dev/null
sudo iptables -t nat -F
sudo iptables -F
sudo iptables -X

echo "✅ Kubernetes and containerd removed completely."
