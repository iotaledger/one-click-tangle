# How to run IOTA mainnet Hornet nodes on a Kubernetes environment

In this tutorial you will learn how to run [IOTA](https://wiki.iota.org/chrysalis-docs/welcome) mainnet [Hornet](https://wiki.iota.org/hornet/welcome) nodes on a Kubernetes (K8s) environment. [Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) is a portable, extensible, open-source platform for managing containerized workloads and services, that facilitates both **declarative configuration** and automation. It has a large, rapidly growing ecosystem. K8s services, support and tools are widely available from multiple cloud providers.

If you are not familiar with K8s we recommend you to start by [learning the technology](https://kubernetes.io/docs/tutorials/kubernetes-basics/).

## Introduction

Running Hornet nodes on K8s can enjoy all the advantages of a declarative, managed, portable and automated container-based environment. However, as Hornet nodes are stateful services with several persistence, configuration and peering requirements, the task can be challenging. To overcome it, the IOTA Foundation under the [one-click-tangle](https://github.com/iotaledger/one-click-tangle) project is providing K8s recipes and associated scripts that intend to educate developers on how nodes can be automatically deployed, peered and load balanced in a portable way.

Furthermore, a ready to be used script allows running multiple Hornet instances "in one click" in your K8s environment of choice, but also provides a blueprint of the best practices to be followed by K8s administrators when deploying production-ready environments.

## Deployment using the "one click" script

For running the [one click script](https://github.com/iotaledger/one-click-tangle/hornet-mainnet-k8s/README.md) you need to get access to a K8s cluster. For local development we recommend [microk8s](https://microk8s.io/).
In addition you need the [kubectl](https://kubernetes.io/docs/tasks/tools/) command line tool properly configured to get access to your cluster.

The referred script accepts the following parameters (passed as command line variables):

* `NAMESPACE`: The namespace where the one-click script will create the K8s objects. `tangle` by default.
* `PEER`: A multipeer address that will be used to peer your nodes with. If no address is provided, autopeering will be configured.
* `INSTANCES`: The number of Hornet instances to be deployed. `1` by default.
* `INGRESS_CLASS`: The class associated to the [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) object that will be used to expose externally the Node API endpoint so that it can be load balanced. It can depend on the target K8s environment. `nginx` by default.

For deploying a Hornet node using the default parameter values you just need to run

```sh
hornet-k8s.sh deploy
```

After executing the script different Kubernetes objects will be created (under the `tangle` namespace) as enumerated below (you can see the `kubectl` instruction to get details about them):

* [Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) where all the objects live, `tangle` by default.

```sh
kubectl get namespaces
```

```ascii
NAME              STATUS   AGE
default           Active   81d
tangle            Active   144m
kube-node-lease   Active   81d
kube-public       Active   81d
kube-system       Active   81d
```

* A [Statefulset](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) (named `hornet-set`) that controls the different Hornet instances and enables scaling them.

```sh
 kubectl get statefulset -n tangle -o=wide
```

```ascii
NAME         READY   AGE   CONTAINERS   IMAGES
hornet-set   1/1     20h   hornet       gohornet/hornet:1.1.3
```

* One [Pod](https://kubernetes.io/docs/concepts/workloads/pods/) per Hornet Node bound to our Statefulset. A pod is actually an artefact that executes the Hornet Docker container.

```sh
kubectl get pods -n tangle
```

```ascii
NAME           READY   STATUS    RESTARTS   AGE
hornet-set-0   1/1     Running   0          20h
```

You may have noticed that the name of the pod is the concatenation of the name of the Statefulset `hornet-set` plus an index indicating the pod number in the set (`0`). If we scaled our Statefulset to `2` then we would have two pods (`hornet-set-0` and `hornet-set-1`).

* One [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) bound to each instance declared on the Statefulset. It is used to store permanently all the files corresponding to the internal databases and snapshots of the Hornet Node.

```sh
kubectl get pvc -n tangle -o=wide
```

```ascii
NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
hornet-ledger-hornet-set-0   Bound    pvc-905fe9c7-6a10-4b29-a9fd-a405fd49a5fd   20Gi       RWO            standard       157m
```

* [Service](https://kubernetes.io/es/docs/concepts/services-networking/service/) objects:
  * One Service object which exposes the REST API of the nodes. It is actually a load balancer to port `14625` of **all** the Nodes.
  * One Service object **per Hornet instance** (in our example just one) which exposes as a "NodePort" the gossip, dashboard and autopeering endpoints.

```sh
kubectl get services -n tangle -o=wide
```

```ascii
NAME          TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                                          AGE   SELECTOR
hornet-0      NodePort   10.60.4.75     <none>        15600:30744/TCP,8081:30132/TCP,14626:32083/UDP   19h   statefulset.kubernetes.io/pod-name=hornet-set-0
hornet-rest   NodePort   10.60.3.96     <none>        14265:31480/TCP                                  19h   app=hornet
```

Additionally, you can run  `kubectl describe services -n tangle` to get more details about the endpoints supporting the referred Services.

Note: The name of the Services is important as will allow to address them by DNS name within the cluster. For instance, if you want to peer two nodes within the cluster you can refer 

* A [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) that contains the configuration applied to each Hornet Node, including the peering configuration. (Remember that our Hornet nodes, that belong to an Statefulset, are peered among them). 

```sh
kubectl get configmap -n tangle -o=wide
```

```ascii
NAME               DATA   AGE
hornet-config      6      19h
kube-root-ca.crt   1      19h
```

Likewise, `kubectl describe configmap hornet-config` can be run to obtain more details about the ConfigMap.

* [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) of the Nodes (keys, etc.). Two secrets are created:

  * `hornet-secret` which contains secrets related to the dashboard credentials (hash and salt).
  * `hornet-private-key` contains the Ed25519 private keys of each node.

```sh
kubectl get secrets -n tangle -o=wide
```

```ascii
NAME                  TYPE                                  DATA   AGE
default-token-fks6m   kubernetes.io/service-account-token   3      20h
hornet-private-key    Opaque                                3      20h
hornet-secret         Opaque                                2      20h
```

### Getting access to your Hornet Node

Once your Hornet Node has been deployed on the cluster you would want to get access to it from the outside. Fortunately that is easy as we have already created [K8s Services of type NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport). It essentially means that your Hornet Node will be accessible through certain ports published on the Kubernetes machine where Hornet is actually running.

If you execute:

```sh
kubectl get services -n tangle
```

```ascii
hornet-0      NodePort   10.60.4.75     <none>        15600:30744/TCP,8081:30132/TCP,14626:32083/UDP   20h
hornet-rest   NodePort   10.60.3.96     <none>        14265:31480/TCP                                  20h
```

In the example above the REST API endpoint of your Hornet Node will be accessible through the port `31480` of a K8s machine. Likewise, the Hornet dashboard will be exposed on the port `30744`.

If you are running microk8s locally in your machine you will typically have only one K8s machine running as a virtual machine in your desktop or laptop. Usually the IP address of such a virtual machine is `192.168.64.2`. Nonetheless you can double check such IP address by displaying your 
current kubectl configuration:

```sh
kubectl config view | grep server
```

and you will get an output similar to (that will correspond to the endpoint of the [K8s API Server](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/).

```ascii
server: https://192.168.64.2:16443
```

### Working with multiple instances



## Deep dive. The "one-click" script internals




## Google Kubernetes environment (GKE) specifics



## Amazon Kubernetes environment (EKS) specifics



## Conclusions

