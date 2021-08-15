#!/bin/sh
set -o errexit

kind create cluster --name devio --config kind-calico.yaml

curl https://docs.projectcalico.org/v3.17/manifests/calico.yaml | kubectl apply -f - 
