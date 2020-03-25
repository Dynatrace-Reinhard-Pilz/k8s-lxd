#!/bin/sh
if [ "$(whoami)" = "root" ] ; then
    echo "$(whoami)"
    sudo -H -u ubuntu bash -c 'curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube.sh | sh'
    exit 0
fi
if [[ $(hostname) =~ .*master.* ]]
then
    curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube-master.sh | sh
fi
if [[ $(hostname) =~ .*worker.* ]]
then
    curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube-worker.sh | sh
fi