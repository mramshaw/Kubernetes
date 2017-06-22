# Local Persistent Volume

## Motivation

Create a __local__ persistent volume (also known as a __hostPath__ persistent volume) and then spin up a local nginx.

[This is suitable for testing but the _preferred method_ is to create the persistent volume via a cloud provider. This would normally take the form of network storage but could also be SSD if latency is an issue (and cost isn't). Nevertheless, there's a lot to be said for being able to see how things work in a more traditional way.]

Kubernetes has the abstraction of a persistent volume claim (__pvc__) to request persistent storage. In this example the request is for 3 GiB while the persistent volume has 10 GiB available.

## Prerequisites

* __kubectl__ installed.
* __minikube__ installed.

## Preparation

	$ chmod +x startup.sh teardown.sh

## Startup

	$ ./startup.sh

## Testing

It may take some time for things to spin up, repeat the next command until __local-pv-pod__ shows as __Running__:

	$ kubectl get pods -o wide

Install curl for testing:

	$ kubectl exec -it local-pv-pod -- /bin/bash
	root@local-pv-pod:/# apt-get update

	< ... >

	root@local-pv-pod:/# apt-get install curl 

Use curl to test our local nginx:

	root@local-pv-pod:/# curl localhost
	<h1>Hello from Kubernetes storage</h1>
	root@local-pv-pod:/# exit

Optional:

	$ kubectl describe pod local-pv-pod

	$ kubectl get pvc local-pv-claim

	$ kubectl describe pvc local-pv-claim

	$ kubectl get pv local-pv

	$ kubectl describe pv local-pv

	$ kubectl annotate pv local-pv pv.beta.kubernetes.io/gid=1234

	$ kubectl describe pv local-pv

## Teardown

	$ teardown.sh

## Versions

* kubectl	__v1.6.4__
* minikube	__v0.20.0__

## Credits

Based on https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/
