#!/bin/sh
if [ "$(whoami)" = "root" ] ; then
    echo "$(whoami)"
    sudo -H -u ubuntu bash -c 'curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/remote-exec.sh | bash'
    exit 0
fi
echo "$(whoami)" | tee -a "$HOME/$(whoami)"