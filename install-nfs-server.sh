#!/bin/bash
sudo apt-get -yq install nfs-kernel-server
sudo mkdir -p /storage
sudo mkdir -p /storage/pv0001
sudo mkdir -p /storage/pv0002
sudo mkdir -p /storage/pv0003
sudo mkdir -p /storage/pv0004
sudo mkdir -p /storage/pv0005
sudo mkdir -p /storage/pv0006
sudo chown -R nobody:nogroup /storage
sudo chmod -R 777 /storage
echo "/storage  *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
# sudo ufw allow from 192.168.1.0/24 to any port nfs
# sudo ufw allow from 192.168.1.0/24 to any port ssh
# sudo ufw enable