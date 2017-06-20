# Stateful MySQL with Kubernetes

## Motivation

Create a persistent volume in AWS or GCE and then spin up a stateful MySQL database.

[Creating a persistent volume (__pv__) varies depending on the cloud provider, hence the persistent volume claim (__pvc__) abstraction.]

AWS uses the concept of a volume identifier (__volumeID__) to identify a persistent volume, whereas GCE uses a disk name (__pdName__). In the steps below, this will result in slightly different steps depending on the cloud provider, although most of the steps are common to both.

The MySQL deployment will be simply configured with a password, this is obviously insecure but acceptable for testing.

## Prerequisites

* Cloud (either AWS or GCE) account, command-line tools (__aws__ or __gcloud__) installed.
* Cloud regions or zones specified for local command-line use.
* Cloud credentials stored for local command-line use.
* __kubectl__ installed.
* [Optional] __minikube__ installed.

## Preparation

	$ chmod +x AWS_startup.sh AWS_teardown.sh
OR

	$ chmod +x GCE_startup.sh GCE_teardown.sh

## Startup

#### AWS

	$ aws ec2 create-volume --availability-zone us-west-2b --size 10 --volume-type gp2

Note the __Volume ID__, then edit __mysql-pv-aws.yaml__ to use that volume (vol-xxxxxxxx in the example).

	$ ./AWS_startup.sh

#### GCE

	$ ./GCE_startup.sh

[Shorter than AWS as it's easier to script with a __pdName__ than a __volumeId__.]

## Testing

It may take a while for things to spin up, repeat the next command until there is an I.P. address:

	$ kubectl get pods -l app=mysql -o wide

[Note the __I.P. address__ for use below.]

	$ kubectl run -it --rm --image=mysql:5.7 mysql-client -- mysql -h 172.17.0.4 -ppassword
	If you don't see a command prompt, try pressing enter.
	mysql> \s
	--------------
	mysql  Ver 14.14 Distrib 5.7.18, for Linux (x86_64) using  EditLine wrapper

	< ... >

	mysql> exit
	Bye

Optional:

	$ kubectl describe deployment mysql

	$ kubectl get pvc mysql-pv-claim

	$ kubectl describe pvc mysql-pv-claim

	$ kubectl get pv mysql-pv

	$ kubectl describe pv mysql-pv

## Teardown

#### AWS

	$ ./AWS_teardown.sh

Note the __Volume ID__ (there may be more than one, note the one created earlier), then delete it.

	$ aws ec2 delete-volume --volume-id vol-xxxxxxxx

#### GCE

	$ ./GCE_teardown.sh

[Again, shorter than AWS as it's easier to script with a __pdName__ than a __volumeId__.]

## Credits

Based on https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/

[Worth a read for some of the finer details of configuring a stateful Kubernetes deployment.]
