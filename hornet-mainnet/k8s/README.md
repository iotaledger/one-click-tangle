# Hornet Chrysalis Node on Kubernetes

## Prerequisites

* Get access to a Kubernetes (K8s) cluster and install the `kubectl` command line tool.

## Usage

* Make the bash script executable by running

```
chmod +x hornet-k8s.sh
```

* Deploy a Hornet Node connected to the Chrysalis mainnet

```
PEER=<peer_multiAddress> ./hornet-k8s.sh deploy
```

The `peer_multiAddress` parameter is optional and must conform to the format specified [here](https://hornet.docs.iota.org/post_installation/peering.html). If no peer specified [autopeering](https://hornet.docs.iota.org/post_installation/peering/#autopeering) will be enabled. 

Optionally a Docker image name can be passed, even though, by default, the image name present in the `hornet.yaml` file will be used, usually `gohornet/hornet:latest`. 

A back slash should be added wherever there is a forward slash. For example, when defining the docker image `gohornet/hornet:latest` should be `gohornet\/hornet:latest` and a peer multiaddress like `/ip4/x.x.x.x/tcp/15600/p2p/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` should be `\/ip4\/x.x.x.x\/tcp\/15600\/p2p\/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` to avoid any error occurring during running or installing hornet.

*By default the Node will be deployed under the `tangle` namespace*

* Undeploy Hornet by running
```
./hornet-k8s.sh undeploy
```

* Scale Hornet by running
```
INSTANCES=<number of instances> ./hornet-k8s.sh scale
```

If `INSTANCES=0` then your Hornet node will be stopped. 

* Update Hornet to the latest version known at Docker Hub (`gohornet/hornet:latest`) by running
```
./hornet-k8s.sh update
```

## Getting access to your Hornet Node

Your Hornet node(s) will be exposed through K8s "Nodeport" Services. Such Services are:

* `hornet-rest` it is a K8s Service that exposes the REST endpoint and might be served by multiple Hornet nodes. 
* `hornet-tcp-<n>` one or more K8s Services that exposes the gossip and dashboard and it is only served by one Hornet node. 

In order to know the ports on the K8s Workers where these Services are exposed, you can run (assuming you are using the `tangle` K8s namespace): 

```
kubectl -n tangle describe service hornet-rest
```

```
kubectl -n tangle describe service hornet-tcp-1
```

## Additional parameters

* `NAMESPACE`: conveys a Kubernetes namespace to be used to deploy Hornet. It will be created if it does not exist yet
* `IMAGE`:  conveys the Hornet image to be used, particularly when an update is performed. 

## Troubleshooting

* [Autopeering](https://hornet.docs.iota.org/post_installation/peering/#autopeering) is only enabled if no peer address is provided. To check that autopeering is working correctly `node.enablePlugins` must include `"Autopeering"`.

Ensure that there are entry nodes in the `p2p.autopeering.entryNodes`. Entry nodes are encoded in `multiaddr` format.

NB: The `update` command will not update to new versions of the config files as they may contain local changes that cannot be merged with the upstream changes. If that is the case you would need to stop Hornet, merge your current config files with the config files at [https://github.com/iotaledger/one-click-tangle/blob/chrysalis/hornet-mainnet/config/config.json](https://github.com/iotaledger/one-click-tangle/blob/chrysalis/hornet-mainnet/config/config.json) and then deploy again Hornet. 
