#!/bin/sh
# if [ "$(whoami)" != "root" ] ; then
#    echo "Please run as root"
#    exit
# fi
sudo rm -Rf /tmp/kube-install >/dev/null 2>&1
sudo mkdir -p /tmp/kube-install >/dev/null 2>&1

grep -q "deb https://apt.kubernetes.io/ kubernetes-xenial main" /etc/apt/sources.list.d/kubernetes.list >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
fi

sudo apt-get update
sudo apt-get -yq upgrade
sudo apt-get -yq autoremove
sudo apt-get -yq install docker.io apt-transport-https curl jq iptables arptables ebtables linux-modules-5.3.0-42-generic nfs-common

sudo systemctl enable docker
sudo sed -i -e 's/containerd.sock/containerd.sock\ --exec-opt\ native.cgroupdriver=systemd/' /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl start docker
sudo usermod -aG docker ubuntu
sudo usermod -aG docker root
# newgrp

sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy

sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' | sudo tee -a /etc/default/kubelet
sudo systemctl enable kubelet
sudo systemctl start kubelet

sudo mknod /dev/kmsg c 1 11
sudo echo "[Unit]" | sudo tee -a /etc/systemd/system/mknod_kmsg.service
sudo echo "After=network.service" | sudo tee -a /etc/systemd/system/mknod_kmsg.service
sudo echo "" | sudo tee -a /etc/systemd/system/mknod_kmsg.service
sudo echo "[Service]" | sudo tee -a /etc/systemd/system/mknod_kmsg.service
sudo echo "ExecStart=mknod /dev/kmsg c 1 11" | sudo tee -a /etc/systemd/system/mknod_kmsg.service
sudo echo "" | sudo tee -a /etc/systemd/system/mknod_kmsg.service
sudo echo "[Install]" | sudo tee -a /etc/systemd/system/mknod_kmsg.service
sudo echo "WantedBy=default.target" | sudo tee -a /etc/systemd/system/mknod_kmsg.service
sudo chmod 664 /etc/systemd/system/mknod_kmsg.service
sudo systemctl daemon-reload
sudo systemctl enable mknod_kmsg.service