#!/bin/sh
cd ~
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.5.1
export PATH=$PWD/bin:$PATH
istioctl manifest apply --set profile=demo
kubectl label namespace default istio-injection=enabled
cd ~