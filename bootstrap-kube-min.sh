#!/bin/bash
until su ubuntu
do
  sleep 0.1
done

cd
echo "[*] Installing latest updates"
echo "... apt-get update"
sudo apt-get update >/dev/null 2>&1
echo "... apt-get -yq upgrade"
sudo apt-get -yq upgrade >/dev/null 2>&1

if [[ $(hostname) =~ .*master.* ]]
then

  echo "[*] Initialize Kubernetes Cluster"
  IP_ADDRESS=`ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1`
  # echo "... API Server will advertise address $IP_ADDRESS"
  HOST_NAME=$(hostname -f)
  # echo "... Certificates for API Server will also work for host name $HOST_NAME"
  # echo "... kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$IP_ADDRESS --apiserver-cert-extra-sans=$HOST_NAME --ignore-preflight-errors=all"
  echo "... kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all"
  # echo "...   please have a look into $HOME/kubeadm_init.log in case that critical step fails"
  # sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$IP_ADDRESS --apiserver-cert-extra-sans=$HOST_NAME --ignore-preflight-errors=all >> ~/kubeadm_init.log 2>&1
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all >> ~/kubeadm_init.log 2>&1

  echo "[*] Creating .kube/config file for user $USER"
  echo "... mkdir ~/.kube"
  mkdir ~/.kube
  echo "... cp /etc/kubernetes/admin.conf ~/.kube/config"
  sudo cp /etc/kubernetes/admin.conf ~/.kube/config
  echo "... chown -R ubuntu:ubuntu ~/.kube"
  sudo chown -R ubuntu:ubuntu ~/.kube
  
#  echo "[*] Allowing to schedule pods on master node"
#  echo "... kubectl taint node k8s-master node-role.kubernetes.io/master:NoSchedule-"
#  kubectl taint node k8s-master node-role.kubernetes.io/master:NoSchedule-

  echo "[*] Deploying flannel network"
  sed -i -e "s/LOCALIP/$IP_ADDRESS/" ~/k8s-lxd/kube-flannel.yaml
  echo "... kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
  kubectl apply -f ~/k8s-lxd/kube-flannel.yaml >/dev/null 2>&1
  
#  echo "[*] Installing NFS Server"
#  echo "... bash ~/k8s-lxd/install-nfs-server.sh"
#  bash ~/k8s-lxd/install-nfs-server.sh
  
#  echo "[*] Configuring Persistent Storage Volumes"
#  echo "... kubectl apply -f ~/k8s-lxd/persistent-storage.yaml"
#  kubectl apply -f ~/k8s-lxd/persistent-storage.yaml

  echo "[*] Deploying Kubernetes Dashboard"
  echo "... kubectl create namespace kubernetes-dashboard"
  kubectl create namespace kubernetes-dashboard
  mkdir ~/certs
  cd ~/certs
  echo "... openssl genrsa -out dashboard.key 2048"
  openssl genrsa -out dashboard.key 2048
  echo "... openssl rsa -in dashboard.key -out dashboard.key"
  openssl rsa -in dashboard.key -out dashboard.key
  echo "... openssl req -sha256 -new -key dashboard.key -out dashboard.csr -subj '/CN=localhost'"
  openssl req -sha256 -new -key dashboard.key -out dashboard.csr -subj '/CN=localhost'
  echo "... openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt"
  openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt
  echo "... kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kubernetes-dashboard"
  kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kubernetes-dashboard
  cd ~
  echo "... kubectl create -f  ~/k8s-lxd/kubernetes-dashboard.yaml"
  sed -i -e "s/LOCALIP/$IP_ADDRESS/" ~/k8s-lxd/kubernetes-dashboard.yaml
  kubectl create -f  ~/k8s-lxd/kubernetes-dashboard.yaml
  echo "... kubectl create -f ~/k8s-lxd/dashboard-admin.yaml"
  kubectl create -f ~/k8s-lxd/dashboard-admin.yaml
  echo "... kubectl create -f ~/k8s-lxd/dashboard-admin-bind-cluster-role.yaml"
  kubectl create -f ~/k8s-lxd/dashboard-admin-bind-cluster-role.yaml
  
  echo "[*] Deploying MetallB"
  echo "... kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml"
  kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
  echo "... kubectl apply -f ~/k8s-lxd/metallb-config-map.yaml"
  kubectl apply -f ~/k8s-lxd/metallb-config-map.yaml
  
#  echo "[*] Installing Helm and Tiller"
#  echo "... bash ~/k8s-lxd/install-helm.sh"
#  bash ~/k8s-lxd/install-helm.sh
  
#  echo "[*] Istio"
#  echo "... bash ~/k8s-lxd/install-istio.sh"
#  bash ~/k8s-lxd/install-istio.sh
  
#  echo "[*] Installing OneAgent Operator"
#  echo "... bash ~/k8s-lxd/dynatrace-operator.sh"
#  bash ~/k8s-lxd/dynatrace-operator.sh
  
  echo "[*] Generating and saving cluster join command to ~/joincluster.sh"
  joinCommand=$(kubeadm token create --print-join-command 2>/dev/null)
  echo "sudo $joinCommand --ignore-preflight-errors=all" > ~/joincluster.sh
  
  
  DASHBOARD_TOKEN=$(kubectl describe secrets -n kubernetes-dashboard $(kubectl -n kubernetes-dashboard get secret | awk '/dashboard-admin/{print $1}') | awk '$1=="token:"{print $2}')
  echo ""
  echo "Access to Kubernetes Dashboard at https://$HOST_NAME:30001/" 
  echo "  for authentication use the token below:"
  echo ""
  echo $DASHBOARD_TOKEN

fi

if [[ $(hostname) =~ .*worker.* ]]
then

  # Join worker nodes to the Kubernetes cluster
  echo "[*] Joining Kubernetes Cluster"
  scp -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa ubuntu@k8s-master.mushroom.home:~/joincluster.sh ~ 
  bash ~/joincluster.sh >> ~/joincluster.log

fi