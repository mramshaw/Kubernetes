#!/bin/bash

echo "Starting minikube (local cloud environment) ..."
minikube start

#echo " "
#echo "Allocating persistent storage (AWS) ..."
#aws ec2 create-volume --availability-zone us-west-2b --size 10 --volume-type gp2

# Could script the capture of Volume ID, but probably not in a future-proof way

echo " "
echo "Creating MySQL persistent volume (AWS) ..."
kubectl create -f ./mysql-pv-aws.yaml

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
