#!/bin/bash

set -eo pipefail

NODES=$(echo worker{1..2})

for NODE in ${NODES}; do
  echo "*** Node: $NODE"
  multipass exec ${NODE} -- bash -c "sudo rm -rf /home/ubuntu/.kube/ /etc/kubernetes"
  multipass exec ${NODE} -- bash -c "sudo mkdir -p /home/ubuntu/.kube/"
  multipass exec ${NODE} -- bash -c "sudo chown ubuntu:ubuntu /home/ubuntu/.kube/"
  multipass transfer kubeconfig.yaml ${NODE}:/home/ubuntu/.kube/config
  multipass exec ${NODE} -- bash -c "sudo kubeadm token create --print-join-command >> kubeadm_join_cmd.sh"
  multipass exec ${NODE} -- bash -c "sudo chmod +x kubeadm_join_cmd.sh"
  multipass exec ${NODE} -- bash -c "sudo sh ./kubeadm_join_cmd.sh"
done

sleep 30
export KUBECONFIG=kubeconfig.yaml
kubectl label node worker1 node-role.kubernetes.io/node=
kubectl label node worker2 node-role.kubernetes.io/node=
kubectl get nodes
echo "############################################################################"
echo "Enjoy :-)"
