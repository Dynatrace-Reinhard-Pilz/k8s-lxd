#!/bin/bash
echo "...... apt-get -yq install nfs-kernel-server"
sudo apt-get -yq install nfs-kernel-server >/dev/null 2>&1
echo "...... mkdir -p /k8s-storage"
sudo mkdir -p /k8s-storage >/dev/null 2>&1
echo "...... mkdir -p /k8s-storage/pv0001"
sudo mkdir -p /k8s-storage/pv0001 >/dev/null 2>&1
echo "...... chown -R nobody:nogroup /k8s-storage"
sudo chown -R nobody:nogroup /k8s-storage >/dev/null 2>&1
echo "...... chmod -R 777 /k8s-storage"
sudo chmod -R 777 /k8s-storage >/dev/null 2>&1
echo "...... cat ~/k8s-lxd/etc_exports | sudo tee -a /etc/exports"
cat ~/k8s-lxd/etc_exports | sudo tee -a /etc/exports >/dev/null 2>&1
echo "...... exportfs -a"
sudo exportfs -a 2>&1
echo "...... systemctl restart nfs-kernel-server"
sudo systemctl restart nfs-kernel-server 2>&1
# sudo ufw allow from 192.168.1.0/24 to any port nfs
# sudo ufw allow from 192.168.1.0/24 to any port ssh
# sudo ufw enable