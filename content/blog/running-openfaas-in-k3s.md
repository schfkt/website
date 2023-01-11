---
title: "Running OpenFAAS on a local kubernetes cluster"
date: 2020-10-31
---

A couple of years ago when I just started familiarizing myself with kubernetes, I found minikube. It let you deploy a local kubernetes cluster within a virtual machine. But I didn't manage to make it work. There were, among others, some issues with compiling of libvirt and kernel modules on Fedora. Eventually I stopped trying and dropped the idea of running k8s locally to play with it.

<!--more-->

Recently I've been experimenting with OpenFAAS to offload certain workload to lambdas. OpenFAAS is similar to other FAAS, but the one that you can run on your own infrastructure. You can deploy it to either k8s or Docker Swarm. I use k8s, so I wanted to test everything out before deploying it to a real Kubernetes cluster.

It turned out there's a much simpler solution to run k8s locally nowadays: k3d. It lets you run a [k3s](https://k3s.io/) cluster, a certified Kubernetes alternative, in docker.

# Creating a cluster

On mac you can install k3d with brew:

```bash
brew install k3d
```

I assume you have already Docker installed. So now you can create a cluster with just these two commands:

```bash
k3d cluster create
k3d kubeconfig merge k3s-default --switch-context
```

Well, actually only the first command creates a cluster. The second one just adds the cluster into your kubeconfig and switches the context to it. Now you can verify that it's running with:

```bash
$ kubectl cluster-info
Kubernetes master is running at https://0.0.0.0:55183
CoreDNS is running at https://0.0.0.0:55183/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://0.0.0.0:55183/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
```

That's pretty awesome: in under a minute we've got a locally running k3s cluster.

# Setting up OpenFAAS

OpenFAAS organization provides a helm chart, so first you need to install helm:

```bash
brew install helm
```

Now you need to add OpenFAAS repository to helm:

```bash
helm repo add openfaas https://openfaas.github.io/faas-netes/
```

By default, OpenFAAS keeps it's own services and functions in two separate namespaces. We need to create them first:

```bash
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
```

Check if it's here:

```bash
$ kubectl get ns
NAME              STATUS   AGE
default           Active   3m24s
kube-system       Active   3m24s
kube-public       Active   3m24s
kube-node-lease   Active   3m24s
openfaas          Active   107s
openfaas-fn       Active   107s
```

Now everything is ready for OpenFAAS deployment:

```bash
helm upgrade openfaas --install openfaas/openfaas \
    --namespace openfaas  \
    --set functionNamespace=openfaas-fn \
    --set generateBasicAuth=true
```

Wait a minute and check the deploys in openfaas namespace:

```bash
$ kubectl -n openfaas get deploy
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
nats                1/1     1            1           31m
queue-worker        1/1     1            1           31m
basic-auth-plugin   1/1     1            1           31m
alertmanager        1/1     1            1           31m
prometheus          1/1     1            1           31m
gateway             1/1     1            1           31m
faas-idler          1/1     1            1           31m
```

# Deploy functions

Now it's time to deploy some lambdas into OpenFAAS. First, install faas-cli:

```bash
brew install faas-cli
```

It's an official cli for OpenFAAS that lets you build, publish and deploy lambdas. In order to authenticate to OpenFAAS gateway obtain the auth password first, it's stored as a k8s secret:


```bash
PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
```

Since we didn't setup ingress to access OpenFAAS gateway, you have to forward a port to be able to interact with it. Do that in a separate shell:

```bash
kubectl port-forward svc/gateway -n openfaas 9091:8080
```

Then try to authenticate to OpenFAAS:

```bash
export OPENFAAS_URL=http://127.0.0.1:9091
echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin --password-stdin
```

Now you can list the functions running in OpenFAAS:

```bash
$ faas-cli -g $OPENFAAS_URL list
Function                        Invocations     Replicas

```

But, of course, it's empty. Since we haven't deployed anything yet. Let's deploy some sample functions that OpenFAAS organization provides:

```bash
faas-cli -g $OPENFAAS_URL deploy -f https://raw.githubusercontent.com/openfaas/faas/master/stack.yml
```

Wait for a couple of seconds and list the functions again:

```bash
$ faas-cli -g $OPENFAAS_URL list
Function                        Invocations     Replicas
wordcount                       0               1
hubstats                        0               1
base64                          0               1
echoit                          0               1
markdown                        0               1
nodeinfo                        0               1
```

Yay! Now we can execute some of them:

```bash
$ curl $OPENFAAS_URL/function/echoit -d "HELLO OPENFAAS"
HELLO OPENFAAS

$ curl $OPENFAAS_URL/function/wordcount -d "HELLO OPENFAAS"
        0         2        14

$ curl $OPENFAAS_URL/function/markdown -d "HELLO **OPENFAAS**"
<p>HELLO <strong>OPENFAAS</strong></p>
```

You can play around with OpenFAAS, check it's web UI also. It's located by the same `OPENFAAS_URL` address used to work with faas-cli. It's pretty basic, but you can see the functions deployed in your cluster, invocations count etc.

And that's it for this time. In the next few posts we'll try to write our own function in go and to learn how to automate OpenFAAS deployment with Terraform.
