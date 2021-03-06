#!/bin/sh
if [ "$(whoami)" = "root" ] ; then
    sudo -H -u ubuntu bash -c 'curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube-worker.sh | bash'
    exit 0
fi
curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube-common.sh | bash

JOINCMD=$(/usr/bin/rsh -n -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l ubuntu k8s-master kubeadm token create --print-join-command 2>/dev/null)
while [ "$JOINCMD" = "" ]
do
  sleep 10
  JOINCMD=$(/usr/bin/rsh -n -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l ubuntu k8s-master kubeadm token create --print-join-command 2>/dev/null)
done
echo "sudo $JOINCMD  --ignore-preflight-errors=all" | /bin/sh