#!/bin/sh
lxc list --columns n --format csv k8s- | \
while IFS= read i; do
    echo "stopping $i"
    lxc stop $i
    echo "deleting $i"
    lxc delete $i
done

sh ./lxc-k8s-launch.sh k8s-master

for i in $(seq 1 3);
do
   sh  ./lxc-k8s-launch.sh k8s-worker-0$i &
done