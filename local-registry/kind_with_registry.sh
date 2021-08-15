#!/bin/sh
set -o errexit

kind_network='kind'
reg_name='kind-registry'
reg_port='5000'

# create registry container unless it already exists
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

reg_host="${reg_name}"

if [ "${kind_network}" = "bridge" ]; then
    reg_host="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "${reg_name}")"
fi

echo "Registry Host: ${reg_host}"


KIND_REGISTRY_ENDPOINT=${reg_host} KIND_REGISTRY_PORT=${reg_port} echo "The name is $KIND_REGISTRY_ENDPOINT and the port is $KIND_REGISTRY_PORT"
KIND_REGISTRY_ENDPOINT=${reg_host} KIND_REGISTRY_PORT=${reg_port} /usr/local/bin/gomplate --file kind-registry-local.tmpl -o templated-config.yaml
KIND_REGISTRY_ENDPOINT=${reg_host} KIND_REGISTRY_PORT=${reg_port} /usr/local/bin/gomplate --file kind-registry-cm.tmpl -o templated-cm.yaml

# create kind cluster 
kind create cluster --config=templated-config.yaml --name devio

# connect the registry to the cluster network
# (the network may already be connected)
docker network connect "kind" "${reg_name}" || true

# export kubeconfig context
kind export kubeconfig --name devio

# apply CM
kubectl apply -f templated-cm.yaml
