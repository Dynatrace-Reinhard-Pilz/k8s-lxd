#!/bin/bash
curl -o helm-v2.16.1-linux-amd64.tar.gz https://get.helm.sh/helm-v2.16.1-linux-amd64.tar.gz 2>&1
tar -zxvf helm-v2.16.1-linux-amd64.tar.gz 2>&1
sudo mv linux-amd64/helm /usr/local/bin/helm 2>&1
sudo mv linux-amd64/tiller /usr/local/bin/tiller 2>&1
