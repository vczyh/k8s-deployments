#!/bin/bash

set -e

echo "安装master"

/bin/bash -c "./install.sh"

# init
if [ ! -n "$proxy_address" ]; then
  echo "pull k8s images from ali and init"
  kubeadm init --pod-network-cidr=192.168.0.0/16 --image-repository=registry.aliyuncs.com/k8sxio
else
  echo "pull k8s images from google and init"
  kubeadm init --pod-network-cidr=192.168.0.0/16
fi

# 设置config
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/profile
source /etc/profile

# 安装calico
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml