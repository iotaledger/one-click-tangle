# Hornet Chrysalis Node on Kubernetes

(For a detailed explanation please read the [tutorial on the IOTA Wiki](https://wiki.iota.org/chrysalis-docs/tutorials/mainnet_hornet_node_k8s)) 

## Prerequisites

* Get access to a Kubernetes (K8s) cluster and install the `kubectl` command line tool.

## Usage

* Make the bash script executable by running

```sh
chmod +x hornet-k8s.sh
```

* Deploy a Hornet Node connected to the Chrysalis mainnet

```sh
PEER=<peer_multiAddress> ./hornet-k8s.sh deploy
```

The `peer_multiAddress` parameter is optional and must conform to the format specified [here](https://hornet.docs.iota.org/post_installation/peering.html). If no peer specified [autopeering](https://hornet.docs.iota.org/post_installation/peering/#autopeering) will be enabled. 

A back slash should be added wherever there is a forward slash. For example, when defining the docker image `iotaledger/hornet:1.2.4` should be `iotaledger\/hornet:1.2.4` and a peer multiaddress like `/ip4/x.x.x.x/tcp/15600/p2p/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` should be `\/ip4\/x.x.x.x\/tcp\/15600\/p2p\/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` to avoid any error occurring during running or installing hornet.

*By default the Node will be deployed under the `tangle` namespace*

By default all the Nodes will be automatically peered among them.

* Undeploy Hornet by running

```sh
./hornet-k8s.sh undeploy
```

* Scale Hornet by running

```sh
INSTANCES=<number of instances> ./hornet-k8s.sh scale
```

If `INSTANCES=0` then your Hornet node will be stopped.

## Getting access to your Hornet Node

Your Hornet node(s) will be exposed through K8s "Node Port" Services. Such Services are:

* `hornet-rest` it is a K8s Service that exposes the REST endpoint and might be served by multiple Hornet nodes.
* `hornet-<n>` one or more K8s Services that exposes the gossip and dashboard and it is only served by one Hornet node.

In order to know the ports on the K8s Workers where these Services are exposed, you can run (assuming you are using the `tangle` K8s namespace):

```sh
kubectl -n tangle describe service hornet-rest
```

```sh
kubectl -n tangle describe service hornet-0
```

## Additional parameters

* `NAMESPACE`: conveys a Kubernetes namespace to be used to deploy Hornet. It will be created if it does not exist yet
* `INGRESS_CLASS`: conveys the ingress class to be used in your Kubernetes environment (by default NGINX). For GKE it should be `gce` and for EKS should be `alb`.

## Troubleshooting

* [Autopeering](https://hornet.docs.iota.org/post_installation/peering/#autopeering) is only enabled if no peer address is provided. To check that autopeering is working correctly `node.enablePlugins` must include `"Autopeering"`.

Ensure that there are entry nodes in the `p2p.autopeering.entryNodes`. Entry nodes are encoded in `multiaddr` format.

## Limitations

Network policies for isolating the Pods are not provided by this version.
