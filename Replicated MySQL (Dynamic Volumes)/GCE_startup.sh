#!/bin/bash

USE_MINIKUBE=N

NUMBER_PODS=4

NUMBER_NODES=4

CLUSTER_NAME=mysql-replicated

ZONE=us-west1-b

if [ $USE_MINIKUBE = "Y" ]
then
    echo "Starting minikube (local cloud environment) ..."
    minikube start --extra-config=kubelet.MaxPods=$NUMBER_PODS
else
    echo "Setting up GCloud cluster (this may take some time)..."
    gcloud container clusters create $CLUSTER_NAME --zone=$ZONE --num-nodes=$NUMBER_NODES

#    echo " "
#    echo "Setting up MySQL storage type ..."
#    kubectl create -f ./mysql-storage-gce.yaml 
fi

echo " "
echo "Setting up MySQL configurations ..."
kubectl create -f ./mysql-configmap.yaml 

echo " "
echo "Setting up MySQL Master service ..."
kubectl create -f ./mysql-svc-master.yaml 

echo " "
echo "Setting up MySQL Slave service ..."
kubectl create -f ./mysql-svc-slave.yaml 

echo " "
echo "Getting services ..."
kubectl get services -o wide -l app=mysql

echo " "
echo "Setting up MySQL stateful set ..."
if [ $USE_MINIKUBE = "Y" ]
then
    kubectl create -f ./mysql-statefulset.yaml 
else
    kubectl create -f ./mysql-statefulset-gce.yaml 
fi

echo " "
echo "Getting MySQL stateful set ..."
kubectl get statefulset -l app=mysql

echo " "
echo "Getting persistent volume claims ..."
kubectl get pvc -o wide -l app=mysql

echo " "
echo "Getting persistent volumes ..."
kubectl get pv -o wide

echo " "
echo "Getting MySQL pods ..."
kubectl get pods -o wide -l app=mysql
