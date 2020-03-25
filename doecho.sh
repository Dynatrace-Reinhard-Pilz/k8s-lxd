#!/bin/sh
if [ "$(whoami)" = "root" ] ; then
    echo "$(whoami)"
    sudo -H -u ubuntu bash -c 'curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/doecho.sh | sh'
else
    curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/doecho.sh | sh
fi
# echo "I am $USER, with uid $UID"
# sudo -H -u ubuntu bash -c 'echo "I am $USER, with uid $UID"'