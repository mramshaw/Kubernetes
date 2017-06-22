#!/bin/bash

echo "Deleting local nginx pod ..."
kubectl delete -f local-pv-pod.yaml

echo " "
echo "Deleting local persistent volume claim ..."
kubectl delete -f local-pv-claim.yaml

echo " "
echo "Deleting local persistent volume ..."
kubectl delete -f local-pv.yaml

echo " "
echo "Deleting local directory and index.html ..."
minikube ssh <<EOF
rm -rf /tmp/data
exit
EOF

echo " "
echo "You may wish to stop minikube ('minikube stop') now."
echo "Optionally, clean up minikube ('minikube delete')."
