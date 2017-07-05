#!/bin/bash

USE_MINIKUBE=N

CLUSTER_NAME=mysql-replicated

ZONE=us-west1-b

echo "Deleting MySQL stateful set (this can take some time) ..."
if [ $USE_MINIKUBE = "Y" ]
then
    kubectl delete -f mysql-statefulset.yaml
else
    kubectl delete -f mysql-statefulset-gce.yaml
fi

echo " "
echo "Deleting MySQL Persistent Volume Claims ..."
kubectl delete pvc -l app=mysql

echo " "
echo "Deleting MySQL Slave service ..."
kubectl delete -f mysql-svc-slave.yaml

echo " "
echo "Deleting MySQL Master service ..."
kubectl delete -f mysql-svc-master.yaml

echo " "
echo "Deleting MySQL configurations ..."
kubectl delete -f mysql-configmap.yaml

if [ $USE_MINIKUBE = "Y" ]
then
    echo " "
    echo "You may wish to stop minikube ('minikube stop') now."
    echo "Optionally, clean up minikube ('minikube delete')."
else
    echo " "
    echo "Deleting GCloud cluster ..."
    gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE

    echo " "
    echo "Getting GCloud clusters (should not be any) ..."
    gcloud container clusters list --filter=name=$CLUSTER_NAME
fi
