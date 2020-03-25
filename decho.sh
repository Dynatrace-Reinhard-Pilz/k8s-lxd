#!/bin/sh
if [ "$(whoami)" = "root" ] ; then
    echo "$(whoami)"
    sudo -H -u ubuntu bash -c 'curl https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/decho.sh | sh'
else
    echo "I am $USER, with uid $UID"
fi
# 
# sudo -H -u ubuntu bash -c 'echo "I am $USER, with uid $UID"'