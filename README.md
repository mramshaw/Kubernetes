# Getting familiar with Kubernetes

## Introduction

This is probably the premiere ___Orchestration framework___ for the __Cloud__.

The main cloud providers (AWS, Azure, Google) all support Kubernetes (generally as a premium offering).

[As Google had already used GCE for their compute engine, their container TLA is __GKE__.]

## Thoughts on the best cloud provider

There's an old photography joke about what the best camera is: "the one you have with you" (the one at home is no use).

Likewise, the best cloud provider is whichever one you know best.

They __all__ have huge eco-systems so learning each providers set of offerings is definitely a non-trivial exercise.

My read on things is that __AWS__ is the leader and likely to stay that way; __Azure__ is the corporate choice for the MS world; and __Google__ is definitely a late-comer but cannot be too heavily discounted (or ignored). For one thing, the presence of Google has led everyone to discount their prices (which is probably not a bad thing).

So in the end overall cost is probably not a good criterion as the charges are likely to continue to go down.

## Running in the Cloud versus running locally

The cloud providers listed all provide either free credits or free services (presumably for evaluation purposes).

They all require a valid credit card too (presumably for identification/authentication/idemnification purposes).

So tread carefully: some of the allocation settings are not set __by default__ to the free tier offerings.

[Generally the ___free___ offerings are limited to the 'micro' or 'small' machine images.]

Premium products (such as Google's Cloud Spanner - which is pretty cool) are generally not free.

Using these will eat into your free credits, so remember to tear everything down when finished.

As with __Docker__ it is possible to run __Kubernetes__ locally, which definitely has some advantages.

For one thing, all of the cloud providers have extensive (and very cluttered) dashboards whereas the command _'__minikube dashboard__'_ will pop open a browser populated with a much less cluttered dashboard (making it much easier to see what is going on).

## Tools

There are 3 main tools, __kubeadm__, __kubectl__, and __minikube__.

For setting up __local__ clusters or for provisioning VMs, __kubeadm__ is probably useful.

However, for dealing with cloud providers (such as AWS, Azure, Google) it is probably not needed.

Having dabbled with all 3 of the listed providers, I can say definitely that it is not necessary to install __kubectl__ locally either.

[Each of the cloud providers recommends that you install their command-line toolset, which definitely make a lot of things simpler, however it ___should___ be possible to perform all needed functions from a web interface (naviagting said web interface is generally non-trivial however).]

For local familiarization, __minikube__ is the way to go - and it requires __kubectl__.

[Minikube is really the local equivalent of a cloud providers command-line toolset.]

Using __minikube__ requires installing some form of virtualization, for linux either __VirtualBox__ or __KVM__ [I chose VirtualBox].

Using either of these probably requires enabling either __VT-x__ or __AMD-v__ hardware virtualization in your __BIOS__.

[In my BIOS this was __Advanced__ -> __CPU Configuration__ -> __Intel Virtualization Technology__]
