#!/bin/bash
su ubuntu
cd
echo "[TASK 01] Installing latest updates via APT-GET"
sudo apt-get update >/dev/null 2>&1
sudo apt-get -yq upgrade >/dev/null 2>&1

echo "[TASK 02] Installing Docker"
sudo apt-get -yq install docker.io >/dev/null 2>&1
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker

echo "[TASK 03] Ensuring legacy binaries are installed"
sudo apt-get install -y iptables arptables ebtables >/dev/null 2>&1
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy >/dev/null 2>&1
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy >/dev/null 2>&1
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy >/dev/null 2>&1
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy >/dev/null 2>&1

echo "[TASK 04] Installing additional support packages"
sudo apt-get install -yq apt-transport-https curl >/dev/null 2>&1

echo "[TASK 05] Adding APT repo for Kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo "[TASK 06] Installing latest updates via APT-GET"
sudo apt-get update >/dev/null 2>&1
sudo apt-get -yq upgrade >/dev/null 2>&1
sudo apt-get -yq autoremove >/dev/null 2>&1

echo "[TASK 07] Installing kubelet, kubeadm and kubectl"
sudo apt-get install -y kubelet kubeadm kubectl >/dev/null 2>&1
sudo apt-mark hold kubelet kubeadm kubectl >/dev/null 2>&1

echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' | sudo tee -a /etc/default/kubelet
sudo systemctl enable kubelet
sudo systemctl start kubelet

sudo mknod /dev/kmsg c 1 11 >/dev/null 2>&1


if [[ $(hostname) =~ .*master.* ]]
then

  # Initialize Kubernetes
  echo "[TASK 08] Initialize Kubernetes Cluster"
  IP_ADDRESS=`ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1`
  HOST_NAME=$(hostname -f)
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$IP_ADDRESS --apiserver-cert-extra-sans=$HOST_NAME --ignore-preflight-errors=all >> ~/kubeadm_init.log 2>&1

  # Copy Kube admin config
  mkdir ~/.kube
  sudo cp /etc/kubernetes/admin.conf ~/.kube/config
  sudo chown -R ubuntu:ubuntu ~/.kube  

  # Deploy flannel network
  echo "[TASK 09] Deploy flannel network"
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

  kubectl create namespace kubernetes-dashboard
  mkdir ~/certs
  cd ~/certs
  openssl genrsa -out dashboard.key 2048
  openssl rsa -in dashboard.key -out dashboard.key
  openssl req -sha256 -new -key dashboard.key -out dashboard.csr -subj '/CN=localhost'
  openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt
  kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kubernetes-dashboard
  cd

  echo "[TASK 10] Cloning Git Repo"
  git clone https://github.com/Dynatrace-Reinhard-Pilz/k8s-lxd.git

  echo "[TASK 11] Installing Dashboard"
  kubectl create -f  ~/k8s-lxd/kubernetes-dashboard.yaml
  kubectl create -f ~/k8s-lxd/dashboard-admin.yaml
  kubectl create -f ~/k8s-lxd/dashboard-admin-bind-cluster-role.yaml

  # Generate Cluster join command
  echo "[TASK 12] Generate and save cluster join command to /joincluster.sh"
  joinCommand=$(kubeadm token create --print-join-command 2>/dev/null)
  echo "sudo $joinCommand --ignore-preflight-errors=all" > ~/joincluster.sh
  
  DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | awk '/^kubernetes-dashboard-token-/{print $1}') | awk '$1=="token:"{print $2}')
  echo "Access to Kubernetes Dashboard at https://$HOST_NAME:30001/ with token" 
  echo $DASHBOARD_TOKEN

fi

if [[ $(hostname) =~ .*worker.* ]]
then

  # Join worker nodes to the Kubernetes cluster
  echo "[TASK 09] Join node to Kubernetes Cluster"
  scp -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa ubuntu@k8s-master.mushroom.home:~/joincluster.sh ~ 
  bash ~/joincluster.sh >> ~/joincluster.log

fi
