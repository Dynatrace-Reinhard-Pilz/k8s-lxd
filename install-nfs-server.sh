#!/bin/bash
sudo apt install nfs-kernel-server
sudo mkdir -p /k8s-storage
sudo mkdir -p /k8s-storage/pv0001
sudo chown -R nobody:nogroup /k8s-storage
sudo chmod -R 777 /k8s-storage
cat ~/k8s-lxd/etc_exports | sudo tee -a /etc/exports >/dev/null 2>&1
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
sudo ufw allow from 192.168.1.0/24 to any port nfs
sudo ufw allow from 192.168.1.0/24 to any port ssh
sudo ufw enable