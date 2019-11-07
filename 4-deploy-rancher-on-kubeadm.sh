#!/bin/bash

set -eo pipefail

export KUBECONFIG=kubeconfig.yaml
kubectl -n kube-system create serviceaccount tiller || true
kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller || true
curl -LOs https://git.io/get_helm.sh
helm version | grep v3.0.0 || bash get_helm.sh --version v3.0.0-rc.3
rm -f get_helm.sh
export HELM_HOME=".helm"
rm -rf .helm
# helm init --service-account tiller --override spec.selector.matchLabels.'name'='tiller',spec.selector.matchLabels.'app'='helm' --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | kubectl apply -f -
# kubectl rollout status deployment tiller-deploy -n kube-system
# sleep 60
#helm install stable/cert-manager --name cert-manager --namespace kube-system --version v0.5.2
#sleep 60
#kubectl -n kube-system rollout status deploy/cert-manager
kubectl create ns cattle-system || true
# kubectl -n cattle-system create secret generic tls-ca --from-file=./ca/rancher/cacerts.pem
# kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=./ca/rancher/cert.pem --key=./ca/rancher/key.pem
# kubectl get secrets -n cattle-system
# using slef signed private CA certificate
# helm install --name rancher rancher-latest/rancher --namespace cattle-system --set hostname=node2  --set ingress.tls.source=secret --set privateCA=true
# helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
# helm init --client-only
release="stable"
helm repo add rancher-$release https://releases.rancher.com/server-charts/$release
helm delete rancher --namespace cattle-system || true
helm install rancher rancher-$release/rancher --namespace cattle-system --set hostname=localhost --set tls=external
echo "############################################################################"
echo "This should take about 2 minutes, please wait ... "
echo "in the meanwhile open a new shell, change to the install dir and run:"
echo "export KUBECONFIG=kubeconfig.yaml"
echo "kubectl get all -A"
echo "to see the status of the deployment"
echo "Your browser should open in about 2 minutes and point to:"
echo "https:/127.0.0.1:4443"
echo "############################################################################"
# sleep 300
kubectl -n cattle-system rollout status deploy/rancher
# sleep 5
echo ""
rancher=`kubectl get pods -n cattle-system | grep rancher |awk 'NR==1{print $1}'`
open https:/127.0.0.1:4443
echo "############################################################################"
echo "Hope you have fun with kubeadm on multipass"
echo "If you have any questions and would like to join us on Slack, here you go:"
echo "https://kubernauts-slack-join.herokuapp.com/"
kubectl port-forward -n cattle-system $rancher 4443:443 &

