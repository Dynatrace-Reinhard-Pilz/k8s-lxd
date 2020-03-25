#!/bin/sh
lxc list --columns n --format csv k8s- | sed 1d | \
while IFS= read i; do
    lxc stop $i
    lxc delete $i
done

sh ./lxc-k8s-launch.sh k8s-master &

for i in $(seq 1 5);
do
   sh  ./lxc-k8s-launch.sh k8s-worker-0$i &
done