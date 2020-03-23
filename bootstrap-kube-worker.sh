#!/bin/sh
# if [ "$(whoami)" != "root" ] ; then
#    echo "Please run as root"
#    exit
# fi
curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/prepare-kube.sh | sh

sudo mkdir -p /storage
sudo mkdir -p /storage/pv0001
sudo mkdir -p /storage/pv0002
sudo mkdir -p /storage/pv0003
sudo mkdir -p /storage/pv0004
sudo mkdir -p /storage/pv0005
sudo mkdir -p /storage/pv0006
sudo chown -R nobody:nogroup /storage
sudo chmod -R 777 /storage