#!/bin/bash

echo "Deleting MySQL service ..."
#kubectl delete svc mysql
kubectl delete -f mysql-svc.yaml

echo " "
echo "Deleting MySQL deployment ..."
#kubectl delete deploy mysql
kubectl delete -f mysql-deploy.yaml

echo " "
echo "Deleting MySQL persistent volume claim ..."
#kubectl delete pvc mysql-pv-claim
kubectl delete -f mysql-pv-claim.yaml

echo " "
echo "Deleting MySQL persistent volume ..."
#kubectl delete pv mysql-pv
kubectl delete -f mysql-pv-gce.yaml

echo " "
echo "Deleting MySQL persistent storage (Google Cloud) ..."
gcloud compute disks delete mysql-disk

echo " "
echo "You may wish to stop minikube ('minikube stop') now."
echo "Optionally, clean up minikube ('minikube delete')."
