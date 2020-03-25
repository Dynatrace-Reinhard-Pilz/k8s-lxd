#!/bin/sh
HN=$(hostname 2>/dev/null)
echo "host: $HN"
while [ "$HN" = "" ]
do
  sleep 5
  HN=$(hostname 2>/dev/null)
done
if [ "$(whoami)" = "root" ] ; then
    sudo -H -u ubuntu bash -c 'curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube.sh | bash'
    exit 0
fi
if [[ $(hostname) =~ .*master.* ]]
then
    curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube-master.sh | sh
fi
if [[ $(hostname) =~ .*worker.* ]]
then
    curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Dynatrace-Reinhard-Pilz/k8s-lxd/master/bootstrap-kube-worker.sh | sh
fi