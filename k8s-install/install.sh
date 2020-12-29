#!/bin/bash

#set -e

# 安装最新 Docker
yum remove docker \
	docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine
yum install -y yum-utils
if [ ! -n "$proxy_address" ]; then
  echo "添加 aliyun docker yum repo"
  yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
else
  echo "添加 官方 docker yum repo"
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
fi
yum install -y docker-ce docker-ce-cli containerd.io

# 设置 Cgroup 驱动程序
mkdir -p /etc/docker
cat << EOF | sudo tee /etc/docker/daemon.json
{
  "registry-mirrors": ["${REGISTRY_MIRROR}"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl daemon-reload
systemctl enable docker
systemctl start docker

# 安装最新k8s
if [ ! -n "$proxy_address" ]; then
  echo "添加 aliyun k8s yum repo"
  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
  yum install -y --nogpgcheck kubelet kubeadm kubectl
else
  echo "添加 官方 k8s yum repo"
  cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
  yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
fi

systemctl enable --now kubelet

# 将 SELinux 设置为 permissive 模式（相当于将其禁用）
setenforce 0
 sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo "--------------------------"
# 一些 RHEL/CentOS 7 的用户曾经遇到过问题：由于 iptables 被绕过而导致流量无法正确路由的问题。
# 您应该确保 在 `sysctl` 配置中的 `net.bridge.bridge-nf-call-iptables` 被设置为 1。
cat << EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭 swap
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab

# 命令补全提示
yum install bash-completion -y
echo "source /usr/share/bash-completion/bash_completion" >> /etc/profile
echo "source <(kubectl completion bash)" >> /etc/profile