#!/bin/sh
if [ "$(whoami)" = "root" ] ; then
    echo "$(whoami)"
    sudo -H -u ubuntu bash -c 'curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube-worker.sh | sh'
    exit 0
fi
curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube-common.sh | sh

JOINCMD=`rsh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l ubuntu k8s-master kubeadm token create --print-join-command 2>/dev/null`
while [ "$JOINCMD" = "" ]
do
  echo "command: $JOINCMD"
  sleep 10
  JOINCMD=`rsh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l ubuntu k8s-master kubeadm token create --print-join-command 2>/dev/null`
done
echo "sudo $JOINCMD  --ignore-preflight-errors=all" | /bin/sh