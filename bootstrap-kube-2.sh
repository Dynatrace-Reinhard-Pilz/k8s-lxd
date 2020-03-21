sudo apt-get update && sudo apt-get -yq upgrade
sudo apt-get -yq install docker.io apt-transport-https curl jq
sudo systemctl enable docker && sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker

sudo apt-get install -y iptables arptables ebtables
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy


curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update && sudo apt-get -yq upgrade && sudo apt-get -yq autoremove

sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' | sudo tee -a /etc/default/kubelet
sudo systemctl enable kubelet && sudo systemctl start kubelet

sudo mknod /dev/kmsg c 1 11

---- master ---

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all

mkdir ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown -R ubuntu:ubuntu ~/.kube
echo KUBECONFIG=$HOME/.kube/config | sudo tee -a /etc/environment
export KUBECONFIG=$HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc6/aio/deploy/recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.2.21-192.168.2.240

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin-bind-cluster-role
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: dashboard-admin
  namespace: kubernetes-dashboard

kubectl create namespace dynatrace
LATEST_RELEASE=$(curl -s https://api.github.com/repos/dynatrace/dynatrace-oneagent-operator/releases/latest | grep tag_name | cut -d '"' -f 4)
kubectl create -f https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/kubernetes.yaml
kubectl -n dynatrace create secret generic oneagent --from-literal="apiToken=$API_TOKEN" --from-literal="paasToken=$PAAS_TOKEN"
kubectl apply -f cr.yaml
curl https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/cr.yaml | sed -e "s/skipCertCheck:\ false/skipCertCheck:\ true/" | sed -e "s/tokens:\ \"\"/tokens:\ \"oneagent\"/" | sed -e "s/ENVIRONMENTID.live.dynatrace.com/managed.mushroom.home\/e\/$ENVIRONMENTID/" > cr.yaml



---- worker ---
sudo kubeadm join 192.168.2.5:6443 --token 9uqi0u.bckilvm4ytnan5xp --discovery-token-ca-cert-hash sha256:498822085dd3097a53a2ddb415cf79b8249cf42492f072533ffc0c6c89d4033e --ignore-preflight-errors=all



echo "[*] Cloning Git Repo"
echo "... git clone https://github.com/Dynatrace-Reinhard-Pilz/k8s-lxd.git"
git clone https://github.com/Dynatrace-Reinhard-Pilz/k8s-lxd.git








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
   >> ~/kubeadm_init.log 2>&1

  
  
  echo "... chown -R ubuntu:ubuntu ~/.kube"
  sudo chown -R ubuntu:ubuntu ~/.kube
  
#  echo "[*] Allowing to schedule pods on master node"
#  echo "... kubectl taint node k8s-master node-role.kubernetes.io/master:NoSchedule-"
#  kubectl taint node k8s-master node-role.kubernetes.io/master:NoSchedule-

  echo "[*] Deploying flannel network"
  sed -i -e "s/LOCALIP/$IP_ADDRESS/" ~/k8s-lxd/kube-flannel.yaml
  echo "... "
  kubectl apply -f ~/k8s-lxd/kube-flannel.yaml
  
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