# Stateful MySQL with Kubernetes

## Motivation

Create a stateful MySQL database using a stateful set & dynamic volumes and then spin up two read-only replicas.

Stateful sets are interesting in that they are created __in sequence__, which certainly makes sense when replicating a database. The master (mysql-0) database is created (headless) first, and then the replicas are daisy-chained afterwards. In this case, the creation order will therefore be: 0, 1, 2. When they are taken down, this order is reversed: 2, 1, 0.

The MySQL instances will be configured __without passwords__, this is obviously insecure but acceptable for testing.

## Prerequisites

* Cloud (GCP) account, command-line tools (__aws__ or __gcloud__) installed.
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

In general, rather than run containers on virtual machines _in a virtual machine_, it is probably a better idea to run this exercise in the cloud. With multiple levels of abstraction it can be very hard to grok what is going on, hardware limitations will probably create lots of restarts - probably due to hardware limitiations.

## Startup

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

Now query the replicated __mysql-read-only__ to verify that the data just inserted has indeed been propogated:
	
	$ kubectl run -it --rm --image=mysql:5.7 mysql-client --restart=Never -- mysql -h mysql-read-only -e "SELECT * FROM test.messages"
	+---------+
	| message |
	+---------+
	| hello   |
	+---------+
	$

And now query the replicated __mysql-read-only__ to verify that the load-balancing works as expected (Ctrl-C to end):
	
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
	+-------------+---------------------+
	| @@server_id | NOW()               |
	+-------------+---------------------+
	|         101 | 2017-06-27 23:12:34 |
	+-------------+---------------------+
	^C
	$

#### Simulating downtime

Break the mysql __readiness probe__ in the second replica:

	kubectl exec mysql-2 -c mysql -- mv /usr/bin/mysql /usr/bin/mysql.off

Verify that the __READY__ status of the second replica has transitioned to __1/2__:

	kubectl get pod mysql-2

Fix the mysql __readiness probe__:

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

## Teardown

#### GCE

	$ ./GCE_teardown.sh

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
	Deleted [https://container.googleapis.com/ ... /mysql-replicated].

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

* aws		__1.11.13__
* gcloud	__159.0.0__
* kubectl	__v1.6.4__
* minikube	__v0.20.0__

## Credits

Based on https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/

[Worth a read for a detailed explanation of how the MySQL replication happens, also for the details of configuring a stateful Kubernetes deployment.]
