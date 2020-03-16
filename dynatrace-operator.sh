#!/bin/bash

DEACT_API_TOKEN=***
DEACT_PAAS_TOKEN=***
DEACT_ENVIRONMENTID=***
kubectl create namespace dynatrace
LATEST_RELEASE=$(curl -s https://api.github.com/repos/dynatrace/dynatrace-oneagent-operator/releases/latest | grep tag_name | cut -d '"' -f 4)
kubectl create -f https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/kubernetes.yaml
# kubectl -n dynatrace logs -f deployment/dynatrace-oneagent-operator
kubectl -n dynatrace create secret generic oneagent --from-literal="apiToken=$API_TOKEN" --from-literal="paasToken=$PAAS_TOKEN"
curl https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/cr.yaml | sed -e "s/skipCertCheck:\ false/skipCertCheck:\ true/" | sed -e "s/tokens:\ \"\"/tokens:\ \"oneagent\"/" | sed -e "s/ENVIRONMENTID.live.dynatrace.com/managed.mushroom.home\/e\/$ENVIRONMENTID/" > cr.yaml
kubectl apply -f cr.yaml
