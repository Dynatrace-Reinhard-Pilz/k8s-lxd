#!/bin/bash
rm helm-v2.16.1-linux-amd64.tar.gz
curl -o helm-v2.16.1-linux-amd64.tar.gz https://get.helm.sh/helm-v2.16.1-linux-amd64.tar.gz
tar -zxvf helm-v2.16.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
sudo mv linux-amd64/tiller /usr/local/bin/tiller