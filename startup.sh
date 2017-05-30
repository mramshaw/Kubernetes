#!/bin/bash

echo "Define Coogle Cloud region (US West alternate) ..."
gcloud config set compute/zone us-west1-b

echo " "
echo "Setting up 'auth' ..."
kubectl create -f deployments/auth.yaml
kubectl create -f services/auth.yaml 

echo " "
echo "Setting up 'hello' ..."
kubectl create -f deployments/hello.yaml 
kubectl create -f services/hello.yaml 

echo " "
echo "Setting up frontend configuration ..."
kubectl create configmap nginx-frontend-conf --from-file nginx/frontend.conf 
kubectl create configmap nginx-proxy-conf --from-file=nginx/proxy.conf
kubectl get configmap

echo " "
echo "Setting up frontend certificates (expired) ..."
kubectl create secret generic tls-certs --from-file=tls/
kubectl get secrets

echo " "
echo "Setting up frontend ..."
kubectl create -f deployments/frontend.yaml 
kubectl create -f services/frontend.yaml 

echo " "
echo "Getting services ..."
kubectl get services

echo " "
echo "Getting pods ..."
kubectl get pods

echo " "
echo "Use 'curl -k https://{external hostname}' to verify ..."
