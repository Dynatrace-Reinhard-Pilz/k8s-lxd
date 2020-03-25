#!/bin/sh
if [ "$1" = "" ]; then
    echo "no instance name specified"
    exit 1
fi
lxc launch ubuntu-k8s $1 --profile k8s
sleep 10
curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube.sh | lxc exec $1 bash