#!/bin/sh
# if [ "$(whoami)" != "root" ] ; then
#    echo "Please run as root"
#    exit
# fi
curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/prepare-kube.sh | sh

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all

mkdir ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown -R ubuntu:ubuntu ~/.kube

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-

sudo mkdir -p /storage
sudo mkdir -p /storage/pv0001
sudo mkdir -p /storage/pv0002
sudo mkdir -p /storage/pv0003
sudo mkdir -p /storage/pv0004
sudo mkdir -p /storage/pv0005
sudo mkdir -p /storage/pv0006
sudo chown -R nobody:nogroup /storage
sudo chmod -R 777 /storage

kubectl apply -f https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/local-storage.yaml
kubectl apply -f https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/persistent-storage.yaml


kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc6/aio/deploy/recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/dashboard-admin.yaml
kubectl apply -f https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/dashboard-admin-bind-cluster-role.yaml

kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
kubectl apply -f https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/metallb-config-map.yaml

kubectl patch service kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type": "LoadBalancer"}}'

echo "$(kubeadm token create --print-join-command 2>/dev/null) --ignore-preflight-errors=all" | sudo sh


DEACT_API_TOKEN=***
DEACT_PAAS_TOKEN=***
DEACT_ENVIRONMENTID=***
kubectl create namespace dynatrace
LATEST_RELEASE=$(curl -s https://api.github.com/repos/dynatrace/dynatrace-oneagent-operator/releases/latest | grep tag_name | cut -d '"' -f 4)
kubectl create -f https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/kubernetes.yaml
kubectl -n dynatrace create secret generic oneagent --from-literal="apiToken=$API_TOKEN" --from-literal="paasToken=$PAAS_TOKEN"
curl https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/cr.yaml | sed -e "s/skipCertCheck:\ false/skipCertCheck:\ true/" | sed -e "s/tokens:\ \"\"/tokens:\ \"oneagent\"/" | sed -e "s/ENVIRONMENTID.live.dynatrace.com/managed.mushroom.home\/e\/$ENVIRONMENTID/" > cr.yaml
kubectl apply -f cr.yaml


echo ""
echo "Access Token for Kubernetes Dashboard:"
echo ""
kubectl describe secrets -n kubernetes-dashboard $(kubectl -n kubernetes-dashboard get secret | awk '/dashboard-admin/{print $1}') | awk '$1=="token:"{print $2}'
  
#  echo "[*] Installing Helm and Tiller"
#  echo "... bash ~/k8s-lxd/install-helm.sh"
#  bash ~/k8s-lxd/install-helm.sh
  
#  echo "[*] Istio"
#  echo "... bash ~/k8s-lxd/install-istio.sh"
#  bash ~/k8s-lxd/install-istio.sh