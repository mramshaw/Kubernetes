# Stateful Cassandra with Kubernetes

![Cassandra](images/Cassandra.png)

## Motivation

Create a stateful [Cassandra](http://cassandra.apache.org/) database using a stateful set and then spin up two replicas to make a Cassandra ring.

[Note that this example is Debian-based and uses the OpenJDK 8 JRE rather than a proprietary Java (see [Dockerfile](./Dockerfile)).]

We will use the Cassandra [nodetool utility](http://wiki.apache.org/cassandra/NodeTool) to verify the Cassandra ring status.

This exercise follows on from my [Replicated MySQL (Dynamic Volumes)](https://github.com/mramshaw/Kubernetes/tree/master/Replicated%20MySQL%20(Dynamic%20Volumes)) exercise.

## Prerequisites

* __kubectl__ installed.
* __minikube__ installed.

## Method

There are generally three ways of operating in the cloud:

1. Locally with __minikube__
2. In the cloud, using a dashboard
3. Locally as well as in the cloud, using command-line tools

In this document we will discuss the first option.

## Preparation

The following steps may not be absolutely necessary, but will probably save time and aggravation.

#### Increase minikube's working memory

Cassanda is a ___beast___, so we will need to allocate ___lots___ of memory:

![Minikube memory](images/Minikube_memory.png)

#### Increase minikube's processors

Likewise we will need to allocate ___lots___ of processors:

![Minikube processors](images/Minikube_processors.png)

#### imagePullPolicy

In order to save on network traffic, we will change the [image pull policy](http://kubernetes.io/docs/concepts/containers/images/#updating-images)
 from the recommended __Always__ to __IfNotPresent__ (the default value).

This is not a good idea for a production deployment but will be acceptable for testing.

#### Pull image

To avoid the downloading phase when running __minikube__, perform the following steps:

1. `minikube start`
2. `minikube ssh`
3. `docker images` (optional)
4. `docker pull gcr.io/google-samples/cassandra:v13`
5. `docker images` (optional)
6. `exit`
7. `minikube stop`

This should look as follows:

```bash
$ minikube start
Starting local Kubernetes v1.10.0 cluster...
Starting VM...
Getting VM IP address...
Moving files into cluster...
Downloading kubeadm v1.10.0
Downloading kubelet v1.10.0
Finished Downloading kubeadm v1.10.0
Finished Downloading kubelet v1.10.0
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
Loading cached images from config file.
$ minikube ssh
                         _             _            
            _         _ ( )           ( )           
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __  
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ docker images
REPOSITORY                                    TAG                 IMAGE ID            CREATED             SIZE

< ... >

$ docker pull gcr.io/google-samples/cassandra:v13
v13: Pulling from google-samples/cassandra
d093dc0d702b: Pull complete 
ef5352433e74: Pull complete 
d77cb3c0fe42: Pull complete 
Digest: sha256:7a3d20afa0a46ed073a5c587b4f37e21fa860e83c60b9c42fec1e1e739d64007
Status: Downloaded newer image for gcr.io/google-samples/cassandra:v13
$ docker images
REPOSITORY                                    TAG                 IMAGE ID            CREATED             SIZE

gcr.io/google-samples/cassandra            v13                 d4455a1f13b6        9 months ago        235MB

$ exit
logout
$ minikube stop
Stopping local Kubernetes cluster...
Machine stopped.
$
```

Once __gcr.io/google-samples/cassandra:v13__ (235 MB) shows as an available Docker image in the minikube repository, the downloading portion should be complete. Docker images will persist in minikube until a `minikube delete` command is run.

#### Shutdown period

We will reduce the `terminationGracePeriodSeconds` from the recommended __1800__ (30 minutes in seconds) to __180__ (3 minutes in seconds).

This is probably not ideal for production use, where in-flight requests should have a long timeout,
but is probably an acceptable grace period for testing purposes.

## Startup

Now that we have all of our Docker images present, restart `minikube`.

[Note that this requires running `minikube stop` (as shown above) first.]

#### Minikube limits

The tutorial recommends the following __minikube__ limits:

	$ minikube start --memory 5120 --cpus=4

[This corresponds to 5,120 MB of RAM and 4 CPUs]

This should look roughly as follows:

```bash
$ minikube start --memory 5120 --cpus=4
Starting local Kubernetes v1.10.0 cluster...
Starting VM...
Getting VM IP address...
Moving files into cluster...
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
Loading cached images from config file.
$
```

In general, rather than run containers on virtual machines _in a virtual machine_, it is probably a better idea to run this exercise in the cloud. With multiple levels of abstraction it can be very hard to grok what is going on and hardware limitations will probably create lots of restarts simply due to hardware limitations, both of which will make debugging configuration errors all that much harder.

## Testing

#### Cassandra service

Start a Cassandra service:

```bash
$ kubectl create -f cassandra-service.yaml 
service "cassandra" created
$
```

Verify it (optional) as follows:

```bash
$ kubectl get svc cassandra
NAME        TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
cassandra   ClusterIP   None         <none>        9042/TCP   14s
$
```

#### Cassandra pods

Spin up our statefulset as follows:

    $ kubectl create -f cassandra-statefulset.yaml

[I keep getting the following warning (to be investigated):

```bash
$ kubectl create -f cassandra-statefulset.yaml
statefulset.apps "cassandra" created
Error from server (AlreadyExists): error when creating "cassandra-statefulset.yaml": storageclasses.storage.k8s.io "fast" already exists
$
```

Note that this is only a ___warning___ message; everything spins up as expected.]

We can check on the storage allocation as follows:

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                STORAGECLASS   REASON    AGE
pvc-3e1bdaeb-ef45-11e8-8e5e-080027ef9b14   1Gi        RWO            Delete           Bound     default/cassandra-data-cassandra-0   fast                     11m
pvc-4bc425c2-ef45-11e8-8e5e-080027ef9b14   1Gi        RWO            Delete           Bound     default/cassandra-data-cassandra-1   fast                     11m
pvc-6eca05ba-ef45-11e8-8e5e-080027ef9b14   1Gi        RWO            Delete           Bound     default/cassandra-data-cassandra-2   fast                     10m
$ kubectl get pvc
NAME                         STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
cassandra-data-cassandra-0   Bound     pvc-3e1bdaeb-ef45-11e8-8e5e-080027ef9b14   1Gi        RWO            fast           11m
cassandra-data-cassandra-1   Bound     pvc-4bc425c2-ef45-11e8-8e5e-080027ef9b14   1Gi        RWO            fast           11m
cassandra-data-cassandra-2   Bound     pvc-6eca05ba-ef45-11e8-8e5e-080027ef9b14   1Gi        RWO            fast           10m
$
```

Repeat the following command until pod __cassandra-0__ shows as __Running__:

    $ kubectl get statefulset cassandra

[Depending upon resource availability, this may take some time.]

Eventually, this should show as follows:

```bash
$ kubectl get statefulset cassandra
NAME        DESIRED   CURRENT   AGE
cassandra   3         3         6m
$
```

It may take a while for things to spin up, repeat the next command until pod __cassandra-0__ shows as __Running__:

	$ kubectl get pods -l app=cassandra -o wide

Once that is done, progress can be monitored as follows:

	$ kubectl logs cassandra-0

Eventually, something like the following should indicate that the master pod is up:

```bash
INFO  17:30:10 Starting listening for CQL clients on /0.0.0.0:9042 (unencrypted)...
```

```bash
$ kubectl exec -it cassandra-0 -- nodetool status
Datacenter: DC1-K8Demo
======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  172.17.0.7  99.59 KiB  32           100.0%            aa96dcf8-0dd0-4c78-a961-7163a4357620  Rack1-K8Demo

$
```

#### Startup

We can verify the execution of the container initialization processes as follows:


	$ kubectl logs cassandra-1

	$ kubectl logs cassandra-2

## Teardown

Run the following command:

```bash
$ grace_period=$(kubectl get po cassandra-0 -o=jsonpath='{.spec.terminationGracePeriodSeconds}') \
  && kubectl delete statefulset -l app=cassandra \
  && echo "Sleeping $grace_period" \
  && sleep $grace_period \
  && kubectl delete pvc -l app=cassandra
```

[This will wait for the specified grace period and then delete the persistent volumes.]

Optionally, open another console and watch the teardown (Ctrl-C to end):

```bash
$ kubectl get pods -l app=cassandra -o wide --watch
^C
$
```

Delete the service:

```bash
$ kubectl delete service -l app=cassandra
service "cassandra" deleted
$
```

Finally, stop minikube:

```bash
$ minikube stop
```

## Versions

* kubectl	__2018.09.17__
* minikube	__v0.30.0__

## To Do

- [ ] Add database / replica queries using `cqlsh`
- [ ] Investigate `storageclasses.storage.k8s.io "fast" already exists` warning message
- [ ] Investigate [Seed providers](http://github.com/kubernetes/examples/blob/master/cassandra/java/README.md)

## Credits

Based on http://kubernetes.io/docs/tutorials/stateful-application/cassandra/

[Well worth a read.]
