#!/bin/bash

set -e

# Docker Hub
# export REGISTRY_MIRROR="https://mirror.ccs.tencentyun.com"
# export REGISTRY_MIRROR="http://f1361db2.m.daocloud.io"
#export REGISTRY_MIRROR=https://registry.cn-hangzhou.aliyuncs.com
export REGISTRY_MIRROR="https://d1zbnocg.mirror.aliyuncs.com"

# 是否设置i代理
# export proxy_address="127.0.0.1:7890"

export k8s_version=1.19.6
export docker_version=19.03.9

if [ ! -n "$proxy_address" ]; then
  echo "no proxy"
else
  echo "set proxy $proxy_address"
  export http_proxy=$address
  export https_proxy=$address
fi

if [ $1 == "master" ]; then
  /bin/bash -c "./master.sh"
elif [ $1 == "worker" ]; then
  /bin/bash -c "./worker.sh"
else
  echo "参数错误"
fi


