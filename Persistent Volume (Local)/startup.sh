#!/bin/bash

echo "Starting minikube (local cloud environment) ..."
minikube start

echo " "
echo "Creating a cloud-local directory and index.html ..."
minikube ssh <<EOF
mkdir /tmp/data
echo '<h1>Hello from Kubernetes storage</h1>' > /tmp/data/index.html
exit
EOF

echo " "
echo "Creating local persistent volume ..."
kubectl create -f ./local-pv.yaml

echo " "
echo "Getting persistent volumes (AVAILABLE) ..."
kubectl get pv

echo " "
echo "Creating local persistent volume claim ..."
kubectl create -f ./local-pv-claim.yaml

echo " "
echo "Getting persistent volume claims ..."
kubectl get pvc

echo " "
echo "Getting persistent volumes (BOUND) ..."
kubectl get pv

echo " "
echo "Creating local nginx ..."
kubectl create -f ./local-pv-nginx.yaml

echo " "
echo "Getting pods ..."
kubectl get pods -o wide
