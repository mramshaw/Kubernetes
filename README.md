# Getting familiar with Kubernetes

## Introduction

This is probably the premiere ___Orchestration framework___ for the __Cloud__.

As of August, 2017 all of the major cloud providers belong to the [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/) which supports Kubernetes.

The main cloud providers (AWS, Azure, GCP) all support Kubernetes (generally as a premium offering).

[As Google had already used GCE for their compute engine, their container TLA is __GKE__.]

## Thoughts on the best cloud provider

There's an old photography joke about what the best camera is: "the one you have with you" (the one at home is no use).

Likewise, the best cloud provider is whichever one you know best.

They __all__ have huge eco-systems so learning each providers set of offerings is definitely a non-trivial exercise.

My read on things is that __AWS__ is the leader and likely to stay that way; __Azure__ is the corporate choice for the MS world; and __GCP__ is definitely a late-comer but cannot be too heavily discounted (or ignored). For one thing, the presence of GCP has led everyone to discount their prices (which is probably not a bad thing).

So in the end overall cost is probably not a good criterion as the charges are likely to continue to go down.

#### AWS

It does not seem to be that easy to create a __Kubernetes__ cluster with AWS. While there are [kops](https://github.com/kubernetes/kops) and [kube-aws](https://github.com/kubernetes-incubator/kube-aws), which seem to be actively supported and full-featured, it is a concern that there is no AWS-native tooling. This situation may improve now that Amazon has joined the [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/) - or it may not. Amazon's intentions are not clear but their Adrian Cockcroft has expressed interest in [Containerd](https://containerd.io/) and [Linkerd](https://linkerd.io/). Plus they seem to be experimenting with [kops](https://aws.amazon.com/blogs/compute/kubernetes-clusters-aws-kops/).

Amazon of course have their own [ECS (EC2 Container Service)](https://aws.amazon.com/ecs/) which uses different terminology than Kubernetes (for instance I believe a __task__ approximates to a __pod__) but largely offers the same sorts of services. However the bulk of their customers appear to have opted for Kubernetes over ECS and while their ECS offering can be expected to continue to evolve, they also seem to be hedging their bets with Kubernetes.

#### Azure and Firefox

If you use __firefox__ as your browser, you will need to add a popup exception for __portal.azure.com__ to allow it to open pop-up windows, otherwise Azure's Cloud Shell window will not open (I have left feedback so perhaps this will be fixed). It does not seem to be possible to paste into the Cloud Shell window either, which is annoying.

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

For setting up local clusters or for provisioning VMs, __kubeadm__ is probably useful.

However, for dealing with cloud providers (such as AWS, Azure, GCP) it is probably not needed.

Having dabbled with all 3 of the listed providers, I can confirm that it is not necessary to install __kubectl__ locally either.

[Each of the cloud providers recommends that you install their command-line toolset, which definitely make a lot of things simpler, however it ___should___ be possible to perform all needed functions from a web interface (navigating said dashboard is generally non-trivial however). When operating in the cloud you will use a provided kubectl, so no need to have it installed locally.]

For local familiarization, __minikube__ is the way to go - and it requires __kubectl__.

[Minikube is really the local equivalent of a cloud providers command-line toolset.]

Using __minikube__ also requires installing some form of virtualization; for linux either __VirtualBox__ or __KVM__ [I chose VirtualBox].

Using either of these probably requires enabling either __VT-x__ or __AMD-v__ hardware virtualization in your __BIOS__.

[Don't worry, the minikube startup process will tell you if this setting needs to be enabled or not. Hopefully not.]

[In my BIOS this was __Advanced__ -> __CPU Configuration__ -> __Intel Virtualization Technology__]

## My Projects

These are not in the same order that I went through them, as I progressed I had to backtrack from time to time (when I needed a better grounding on basic concepts) but the order below corresponds to what I think is the difficulty level; in other words the order presented is the order to follow.

These all require __kubectl__ and __minikube__.

#### Persistent Volume (Local)

https://github.com/mramshaw/Kubernetes/tree/master/Persistent%20Volume%20(Local)

The following also require a __cloud provider__ account with its __CLI tools__ installed.

#### Single MySQL (Persistent Volume)

https://github.com/mramshaw/Kubernetes/tree/master/Single%20MySQL%20(Persistent%20Volume)

#### Replicated MySQL (Dynamic Volumes)

https://github.com/mramshaw/Kubernetes/tree/master/Replicated%20MySQL%20(Dynamic%20Volumes)

