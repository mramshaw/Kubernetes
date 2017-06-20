#!/bin/bash

echo "Starting minikube (local cloud environment) ..."
minikube start

echo " "
echo "Allocating persistent storage (GCE) ..."
gcloud compute disks create --size=10GB --zone=us-west1-b mysql-disk

echo " "
echo "Creating MySQL persistent volume (GCE) ..."
kubectl create -f ./mysql-pv-gce.yaml

echo " "
echo "Getting persistent volumes ..."
kubectl get pv -o wide

echo " "
echo "Setting up MySQL service ..."
kubectl create -f ./mysql-svc.yaml 

echo " "
echo "Getting services ..."
kubectl get services -o wide

echo " "
echo "Creating MySQL persistent volume claim ..."
kubectl create -f ./mysql-pv-claim.yaml

echo " "
echo "Getting persistent volume claims ..."
kubectl get pvc -o wide

echo " "
echo "Setting up MySQL deployment ..."
kubectl create -f ./mysql-deploy.yaml 

echo " "
echo "Getting MySQL pod ..."
kubectl get pods -l app=mysql -o wide
