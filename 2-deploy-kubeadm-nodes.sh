#!/bin/bash

set -eo pipefail

NODES=$(echo worker{1..2})

for NODE in ${NODES}; do
  (multipass delete ${NODE} >/dev/null 2>&1; multipass purge) || true
  multipass launch --name ${NODE} --cpus 2 --mem 2G --disk 8G
  multipass info ${NODE}
done

for NODE in ${NODES}; do
  echo "*** Node: $NODE"
  multipass exec ${NODE} -- bash -c 'wget https://packages.cloud.google.com/apt/doc/apt-key.gpg'
  multipass exec ${NODE} -- bash -c 'sudo apt-key add apt-key.gpg'
  multipass exec ${NODE} -- bash -c 'sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"'
  multipass exec ${NODE} -- bash -c 'sudo apt-get update && sudo apt-get install -y apt-transport-https'
  multipass exec ${NODE} -- bash -c 'sudo apt-get -y dist-upgrade'
  multipass exec ${NODE} -- bash -c 'curl https://releases.rancher.com/install-docker/18.09.sh | sh'
  # Setup daemon.
  multipass transfer daemon.json ${NODE}:
  multipass exec ${NODE} -- bash -c 'sudo cp /home/ubuntu/daemon.json /etc/docker/daemon.json'
  multipass exec ${NODE} -- bash -c 'sudo mkdir -p /etc/systemd/system/docker.service.d'
  # Restart docker.
  multipass exec ${NODE} -- bash -c 'sudo systemctl daemon-reload'
  multipass exec ${NODE} -- bash -c 'sudo systemctl restart docker'
  multipass exec ${NODE} -- bash -c 'sudo usermod -aG docker ubuntu'
  multipass exec ${NODE} -- bash -c 'sudo apt-get install -y kubelet kubeadm kubectl'
  multipass exec ${NODE} -- bash -c 'sudo apt-mark hold kubelet kubeadm kubectl'
  multipass exec ${NODE} -- bash -c 'sudo swapoff -a'
  multipass exec ${NODE} -- bash -c "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
  multipass exec ${NODE} -- bash -c 'sudo sysctl net.bridge.bridge-nf-call-iptables=1'
  multipass exec ${NODE} -- bash -c 'sudo apt -y autoremove'
done

echo "Now running kubeadm join nodes"
echo "We're ready soon :-)"

