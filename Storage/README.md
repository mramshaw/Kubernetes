# Kubernetes Storage

As there are multiple cloud providers, so there are multiple storage providers.

Each provider does things slightly differently, hence the _Storage Class_ and _Persistent Volume Claim_ abstractions. __Storage classes__ define - as expected - classes of storage (which vary by provider). __Persistent volume claims__ are a pluggable component that can represent different types of storage (__persistent volumes__) that vary by provider.

## Storage Classes

Cluster Administrators (cluster-admin) or Storage Administrators (storage-admin) define and create the StorageClass objects that users can request without needing any intimate knowledge about the underlying storage volume sources.

Show the storage classes:

	$ kubectl get storageclass

Flag the __slow-gce__ storage class as __default__:

	$ kubectl annotate storageclass slow-gce storageclass.beta.kubernetes.io/is-default-class=true

Remove the __default__ flag from the __standard__ storage class:

	$ kubectl annotate storageclass standard storageclass.beta.kubernetes.io/is-default-class-

Show the storage classes:

	$ kubectl get storageclass

#### Azure

The name of the default storage class in Azure is __default__.

Show the storage classes:

	$ kubectl get storageclass
	NAME                TYPE
	default (default)   kubernetes.io/azure-disk
	$

Show the storage claims (persistent volume claims):

	$ kubectl get pvc
	NAME           STATUS    VOLUME      CAPACITY   ACCESSMODES   STORAGECLASS   AGE
	data-mysql-0   Bound     pvc-9b...   10Gi       RWO           default        2m
	data-mysql-1   Bound     pvc-d3...   10Gi       RWO           default        36s
	$

Show the storage (persistent volumes):

	$ kubectl get pv
	NAME        CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM                  STORAGECLASS   REASON    AGE
	pvc-9b...   10Gi       RWO           Delete          Bound     default/data-mysql-0   default                  2m
	pvc-d3...   10Gi       RWO           Delete          Bound     default/data-mysql-1   default                  33s
	$

#### GCP

The name of the default storage class in GCP is __standard__.

Show the storage classes:

	$ kubectl get storageclass
	NAME                 TYPE
	standard (default)   kubernetes.io/gce-pd   
	$

Show the storage (persistent volumes):

	$ kubectl get pv
	NAME        CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM                  STORAGECLASS   REASON    AGE
	pvc-a0...   2Gi        RWO           Delete          Bound     default/data-mysql-0   standard                 42m
	pvc-c8...   2Gi        RWO           Delete          Bound     default/data-mysql-1   standard                 41m
	pvc-f0...   2Gi        RWO           Delete          Bound     default/data-mysql-2   standard                 40m
	$

