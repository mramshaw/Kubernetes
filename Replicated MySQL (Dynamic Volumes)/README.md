# Stateful MySQL with Kubernetes

## Motivation

Create a stateful MySQL database using a stateful set & dynamic volumes and then spin up two read-only replicas.

Stateful sets are interesting in that they are created __in sequence__, which certainly makes sense when replicating a database. The master (mysql-0) database is created (headless) first, and then the replicas are daisy-chained afterwards. In this case, the creation order will therefore be: 0, 1, 2. When they are taken down, this order is reversed: 2, 1, 0.

The MySQL instances will be configured __without passwords__, this is obviously insecure but acceptable for testing.

## Prerequisites

* Cloud (GCP) account, command-line tools (__gcloud__) installed.
* Cloud regions or zones specified for local command-line use.
* Cloud credentials stored for local command-line use.
* __kubectl__ installed.
* [Optional] __minikube__ installed.

## Preparation

	$ chmod +x GCE_startup.sh GCE_teardown.sh

#### Minikube

If using __minikube__ it will almost certainly be necessary to allocate a larger than normal number of __pods__:

	$ minikube start --extra-config=kubelet.MaxPods=5

It will also be a very good idea to increase the limits of the underlying __virtual machine__.

In general, rather than run containers on virtual machines _in a virtual machine_, it is probably a better idea to run this exercise in the cloud. With multiple levels of abstraction it can be very hard to grok what is going on, hardware limitations will probably create lots of restarts simply due to hardware limitations, which will make debugging configuration errors all that much harder.

#### GCP

Pod |  Type  | CPU (cores) usage | Memory usage
--- | ------ | ----------------- | ------------
mysql-0	| Master | 0.002 | 302.512 Mi
mysql-1	| Slave | 0.001 | 203.059 Mi
mysql-2	| Slave | 0.001 | 203.621 Mi

## Startup

Run the startup script:

#### GCE

	$ ./GCE_startup.sh

## Testing

It may take a while for things to spin up, repeat the next command until pod __mysql-0__ shows as __Running__:

	$ kubectl get pods -l app=mysql -o wide

#### Startup

Initially __mysql-0__ will probably show as __Init:0/2__, which represents the __init-containers__ phase (as specified in 'mysql-statefulset.yaml') and will be the case until it has pulled down the Docker image for MySQL. The next stage is __Init:1/2__, which will be the case until it has pulled down the Docker image for xtrabackup.

To verify this when running __minikube__:

	$ minikube ssh
	$ docker images

	< ... >

	$ exit

Once both __mysql__ (407.3 MB) and __gcr.io/google-samples/xtrabackup__ (264.9 MB) show as available Docker images in the minikube repository, the downloading portion should be complete. Docker images will persist in minikube until a 'minikube delete' command is run.

To avoid the downloading phase when running __minikube__, perform the following steps before launching the startup script:

	$ minikube ssh
	$ docker pull mysql:5.7
	$ docker pull gcr.io/google-samples/xtrabackup:1.0
	$ docker images

	< verify that mysql and gcr.io/google-samples/xtrabackup are present >

	$ exit

We can verify the execution of the container initialization processes as follows:

	$ kubectl logs mysql-0 -c init-mysql
	$ kubectl logs mysql-0 -c clone-mysql

	$ kubectl logs mysql-1 -c init-mysql
	$ kubectl logs mysql-1 -c clone-mysql

	$ kubectl logs mysql-2 -c init-mysql
	$ kubectl logs mysql-2 -c clone-mysql

#### Replication

Query the replicated __mysql-read-only__ to verify that no data exists:

	$ kubectl run -it --rm --image=mysql:5.7 mysql-client --restart=Never -- mysql -h mysql-read-only -e "SELECT * FROM test.messages"
	ERROR 1146 (42S02) at line 1: Table 'test.messages' doesn't exist
	$

Insert some data into the master __mysql__:

	$ kubectl run -it --rm --restart=Never --image=mysql:5.7 mysql-client -- mysql -h mysql-0.mysql
	If you don't see a command prompt, try pressing enter.
	
	mysql> CREATE DATABASE test;
	Query OK, 1 row affected (0.03 sec)
	
	mysql> CREATE TABLE test.messages (message VARCHAR(250));
	Query OK, 0 rows affected (0.02 sec)

	mysql> INSERT INTO test.messages VALUES ('hello');
	Query OK, 1 row affected (0.03 sec)
	
	mysql> exit

Now query the replicated __mysql-read-only__ to verify that the data just inserted has indeed been propagated:
	
	$ kubectl run -it --rm --image=mysql:5.7 mysql-client --restart=Never -- mysql -h mysql-read-only -e "SELECT * FROM test.messages"
	+---------+
	| message |
	+---------+
	| hello   |
	+---------+
	$

Query the replicated __mysql-read-only__ to verify that the load-balancing works as expected (Ctrl-C to end):
	
	$ kubectl run -it --rm --image=mysql:5.7 mysql-client --restart=Never -- bash -ic "while sleep 1; do mysql -h mysql-read-only -e 'SELECT @@server_id,NOW()'; done"
	If you don't see a command prompt, try pressing enter.
	                                                      +-------------+---------------------+
	| @@server_id | NOW()               |
	+-------------+---------------------+
	|         100 | 2017-06-27 23:12:30 |
	+-------------+---------------------+
	+-------------+---------------------+
	| @@server_id | NOW()               |
	+-------------+---------------------+
	|         100 | 2017-06-27 23:12:31 |
	+-------------+---------------------+
	+-------------+---------------------+
	| @@server_id | NOW()               |
	+-------------+---------------------+
	|         101 | 2017-06-27 23:12:32 |
	+-------------+---------------------+
	+-------------+---------------------+
	| @@server_id | NOW()               |
	+-------------+---------------------+
	|         100 | 2017-06-27 23:12:33 |
	+-------------+---------------------+
	^C
	$

#### Simulating downtime

Break the MySQL __readiness probe__ in the second replica:

	kubectl exec mysql-2 -c mysql -- mv /usr/bin/mysql /usr/bin/mysql.off

Verify that the __READY__ status of the second replica has transitioned to __1/2__:

	kubectl get pod mysql-2

Fix the MySQL __readiness probe__:

	kubectl exec mysql-2 -c mysql -- mv /usr/bin/mysql.off /usr/bin/mysql

Verify that the __READY__ status of the second replica has transitioned back to __2/2__:

	kubectl get pod mysql-2

#### Simulating a crash

Delete the second replica and watch __kubernetes__ recreate it (Ctrl-C to end):

	$ kubectl delete pod mysql-2 && kubectl get pods --watch
	pod "mysql-2" deleted
	NAME      READY     STATUS    RESTARTS   AGE
	mysql-0   2/2       Running   0          1h
	mysql-1   2/2       Running   0         1h
	mysql-2   2/2       Terminating   0         1m
	mysql-2   0/2       Terminating   0         1m
	mysql-2   0/2       Terminating   0         1m
	mysql-2   0/2       Terminating   0         1m
	mysql-2   0/2       Terminating   0         1m
	mysql-2   0/2       Terminating   0         1m
	mysql-2   0/2       Pending   0         0s
	mysql-2   0/2       Pending   0         0s
	mysql-2   0/2       Init:0/2   0         0s
	mysql-2   0/2       Init:1/2   0         19s
	mysql-2   0/2       PodInitializing   0         20s
	mysql-2   1/2       Running   0         21s
	mysql-2   2/2       Running   0         30s
	^C
	$

#### Simulate a network outage (drain the node)

Determine the __node__ of the second replica:

	$ kubectl get pod mysql-2 -o wide
	NAME      READY     STATUS    RESTARTS   AGE       IP          NODE
	mysql-2   2/2       Running   0          16m       10.60.1.6   gke-mysql-replicated-default-pool-1...
	$

Drain the second replica node and watch __kubernetes__ relocate the pod (Ctrl-C to end):

	$ kubectl drain gke-mysql-replicated-default-pool-1... --force --delete-local-data --ignore-daemonsets && kubectl get pod mysql-2 -o wide --watch
	node "gke-mysql-replicated-default-pool-1..." cordoned
	WARNING: Deleting pods with local storage: mysql-2; Ignoring DaemonSet-managed pods: fluentd-gcp-v2.0-...; Deleting pods not managed by ReplicationController, ReplicaSet, Job, DaemonSet or StatefulSet: kube-proxy-gke-mysql-replicated-default-pool-1...
	pod "mysql-2" evicted
	node "gke-mysql-replicated-default-pool-1..." drained
	NAME      READY     STATUS     RESTARTS   AGE       IP        NODE
	mysql-2   0/2       Init:0/2   0          1s        <none>    gke-mysql-replicated-default-pool-2...
	mysql-2   0/2       Init:1/2   0         18s       10.60.4.13   gke-mysql-replicated-default-pool-2...
	mysql-2   0/2       PodInitializing   0         29s       10.60.4.13   gke-mysql-replicated-default-pool-2...
	mysql-2   1/2       Running   0         30s       10.60.4.13   gke-mysql-replicated-default-pool-2...
	mysql-2   2/2       Running   0         40s       10.60.4.13   gke-mysql-replicated-default-pool-2...
	^C
	$

Uncordon the original node:

	$ kubectl uncordon gke-mysql-replicated-default-pool-1...
	node "gke-mysql-replicated-default-pool-1..." uncordoned
	$

#### Simulate a flash crowd (or flash crowd departure)

Scale up the number of replicas (note that the instances are created in order):

	$ kubectl scale --replicas=5 statefulset mysql
	statefulset "mysql" scaled
	$

Watch the replicas get scaled up (Ctrl-C to end):

	$ kubectl get pods -l app=mysql --watch
	NAME      READY     STATUS    RESTARTS   AGE
	mysql-0   2/2       Running   0          1h
	mysql-1   2/2       Running   0         1h
	mysql-2   2/2       Running   0         4m
	mysql-3   0/2       Init:0/2   0         13s
	mysql-3   0/2       Init:1/2   0         18s
	mysql-3   0/2       Init:1/2   0         19s
	mysql-3   0/2       PodInitializing   0         27s
	mysql-3   1/2       Running   0         28s
	mysql-3   2/2       Running   0         37s
	mysql-4   0/2       Pending   0         0s
	mysql-4   0/2       Pending   0         0s
	mysql-4   0/2       Pending   0         8s
	mysql-4   0/2       Init:0/2   0         8s
	mysql-4   0/2       Init:1/2   0         26s
	mysql-4   0/2       Init:1/2   0         27s
	mysql-4   0/2       PodInitializing   0         35s
	mysql-4   1/2       Running   0         36s
	mysql-4   2/2       Running   0         48s
	^C
	$

Check the third replica (mysql-3.mysql):

	$ kubectl run -it --rm --image=mysql:5.7 mysql-client --restart=Never -- mysql -h mysql-3.mysql -e "SELECT * FROM test.messages"
	+----------+
	| message  |
	+----------+
	| hello    |
	+----------+
	$

Check the fourth replica (mysql-4.mysql):

	$ kubectl run -it --rm --image=mysql:5.7 mysql-client --restart=Never -- mysql -h mysql-4.mysql -e "SELECT * FROM test.messages"
	+----------+
	| message  |
	+----------+
	| hello    |
	+----------+
	$

Scaling back down again is also seamless (note that the instances are terminated in reverse order):

	$ kubectl scale --replicas=3 statefulset mysql && kubectl get pods -l app=mysql --watch
	statefulset "mysql" scaled
	NAME      READY     STATUS    RESTARTS   AGE
	mysql-0   2/2       Running   0          1h
	mysql-1   2/2       Running   0         1h
	mysql-2   2/2       Running   0         11m
	mysql-3   2/2       Running   0         7m
	mysql-4   2/2       Terminating   0         6m
	mysql-4   0/2       Terminating   0         7m
	mysql-4   0/2       Terminating   0         7m
	mysql-4   0/2       Terminating   0         7m
	mysql-4   0/2       Terminating   0         7m
	mysql-4   0/2       Terminating   0         7m
	mysql-4   0/2       Terminating   0         7m
	mysql-4   0/2       Terminating   0         7m
	mysql-4   0/2       Terminating   0         7m
	mysql-4   0/2       Terminating   0         7m
	mysql-3   2/2       Terminating   0         8m
	mysql-3   2/2       Terminating   0         8m
	mysql-3   0/2       Terminating   0         8m
	mysql-3   0/2       Terminating   0         8m
	mysql-3   0/2       Terminating   0         8m
	mysql-3   0/2       Terminating   0         8m
	mysql-3   0/2       Terminating   0         8m
	^C
	$

Notice that dynamic persistent volumes claims persist after their pods are scaled down:

	$ kubectl get pvc -l app=mysql
	NAME           STATUS    VOLUME      CAPACITY   ACCESSMODES   STORAGECLASS   AGE
	data-mysql-0   Bound     pvc-a0...   2Gi        RWO           standard       2h
	data-mysql-1   Bound     pvc-c8...   2Gi        RWO           standard       2h
	data-mysql-2   Bound     pvc-f0...   2Gi        RWO           standard       2h
	data-mysql-3   Bound     pvc-15...   2Gi        RWO           standard       18m
	data-mysql-4   Bound     pvc-2b...   2Gi        RWO           standard       17m

Check the __reclaim policy__ for the persistent volumes:

	$ kubectl get pv
	NAME        CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM                  STORAGECLASS   REASON    AGE
	pvc-15...   2Gi        RWO           Delete          Bound     default/data-mysql-3   standard                 18m
	pvc-2b...   2Gi        RWO           Delete          Bound     default/data-mysql-4   standard                 18m
	pvc-a0...   2Gi        RWO           Delete          Bound     default/data-mysql-0   standard                 2h
	pvc-c8...   2Gi        RWO           Delete          Bound     default/data-mysql-1   standard                 2h
	pvc-f0...   2Gi        RWO           Delete          Bound     default/data-mysql-2   standard                 2h
	$

As the reclaim policy is __Delete__ (the default value) for the persistent volumes they should be deleted once their claims are deleted:

	$ kubectl delete pvc data-mysql-3 data-mysql-4
	persistentvolumeclaim "data-mysql-3" deleted
	persistentvolumeclaim "data-mysql-4" deleted
	$

Verify that the underlying persistent volumes are deleted as expected (notice how the persistent volumes transition to __Released__ status first [this is a timing thing and may not always be evident]):

	$ kubectl get pv
	NAME        CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS     CLAIM                  STORAGECLASS   REASON    AGE
	pvc-15...   2Gi        RWO           Delete          Released   default/data-mysql-3   standard                 25m
	pvc-2b...   2Gi        RWO           Delete          Released   default/data-mysql-4   standard                 24m
	pvc-a0...   2Gi        RWO           Delete          Bound      default/data-mysql-0   standard                 2h
	pvc-c8...   2Gi        RWO           Delete          Bound      default/data-mysql-1   standard                 2h
	pvc-f0...   2Gi        RWO           Delete          Bound      default/data-mysql-2   standard                 2h
	$

Verify that the underlying persistent volumes are deleted as expected:

	$ kubectl get pv
	NAME        CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM                  STORAGECLASS   REASON    AGE
	pvc-a0...   2Gi        RWO           Delete          Bound     default/data-mysql-0   standard                 2h
	pvc-c8...   2Gi        RWO           Delete          Bound     default/data-mysql-1   standard                 2h
	pvc-f0...   2Gi        RWO           Delete          Bound     default/data-mysql-2   standard                 2h
	$

## Teardown

Run the teardown script:

#### GCE

	$ ./GCE_teardown.sh 
	Deleting MySQL stateful set ...
	statefulset "mysql" deleted
	 
	Deleting MySQL Persistent Volume Claims ...
	persistentvolumeclaim "data-mysql-0" deleted
	persistentvolumeclaim "data-mysql-1" deleted
	persistentvolumeclaim "data-mysql-2" deleted
	 
	Deleting MySQL Slave service ...
	service "mysql-read-only" deleted
	 
	Deleting MySQL Master service ...
	service "mysql" deleted
	 
	Deleting MySQL configurations ...
	configmap "mysql" deleted
	 
	Deleting GCloud cluster ...
	The following clusters will be deleted.
	 - [mysql-replicated] in [us-west1-b]
	
	Do you want to continue (Y/n)?  Y
	
	Deleting cluster mysql-replicated...done.
	Deleted [https ... mysql-replicated].
	 
	You may wish to stop minikube ('minikube stop') now.
	Optionally, clean up minikube ('minikube delete').
	$

Optionally, open another console and watch the teardown (Ctrl-C to end):

	$ kubectl get pods -l app=mysql --watch
	NAME      READY     STATUS    RESTARTS   AGE
	mysql-0   2/2       Running   0          2h
	mysql-1   2/2       Running   0         2h
	mysql-2   2/2       Terminating   0         36m
	mysql-2   0/2       Terminating   0         36m
	mysql-2   0/2       Terminating   0         36m
	mysql-2   0/2       Terminating   0         36m
	mysql-2   0/2       Terminating   0         36m
	mysql-2   0/2       Terminating   0         36m
	mysql-1   2/2       Terminating   0         2h
	mysql-1   2/2       Terminating   0         2h
	mysql-1   0/2       Terminating   0         2h
	mysql-1   0/2       Terminating   0         2h
	mysql-1   0/2       Terminating   0         2h
	mysql-1   0/2       Terminating   0         2h
	mysql-1   0/2       Terminating   0         2h
	mysql-0   2/2       Terminating   0         2h
	mysql-0   2/2       Terminating   0         2h
	mysql-0   0/2       Terminating   0         2h
	mysql-0   0/2       Terminating   0         2h
	mysql-0   0/2       Terminating   0         2h
	mysql-0   0/2       Terminating   0         2h
	^C
	$

## Versions

* gcloud	__159.0.0__
* kubectl	__v1.6.4__
* minikube	__v0.20.0__

## Credits

Based on https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/

[Worth a read for a detailed explanation of how the MySQL replication happens, also for the details of configuring a stateful Kubernetes deployment.]
