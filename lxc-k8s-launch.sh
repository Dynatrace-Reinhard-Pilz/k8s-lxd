#!/bin/sh
if [ "$1" = "" ]; then
    echo "no instance name specified"
    exit 1
fi
echo "creating $1"
lxc launch ubuntu-k8s $1 --profile k8s
IPI=`lxc list k8s-master --columns 4 --format csv`
while [ "$IPI" = "" ]
do
  sleep 3
  IPI=`lxc list k8s-master --columns 4 --format csv`
done
curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube.sh | lxc exec $1 bash