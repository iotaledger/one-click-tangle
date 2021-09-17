# Hornet Chrysalis Node

You can also use these scripts under the [AWS Marketplace](./README_AWS.md)

## Usage

* Make the bash script executable by running

```
chmod +x hornet.sh
```

* Install a Hornet Node connected to the Chrysalis mainnet

```
./hornet.sh install -p <peer_multiAddress> -i <docker_image>
```

The `peer_multiAddress` parameter is optional and must conform to the format specified [here](https://hornet.docs.iota.org/post_installation/peering.html). If no peer specified [autopeering](https://hornet.docs.iota.org/post_installation/peering/#autopeering) will be enabled. 

Optionally a Docker image name can be passed, even though, by default, the image name present in the `docker-compose.yaml` file will be used, usually `gohornet/hornet:latest`. 

A back slash should be added wherever there is a forward slash. For example, when defining the docker image `gohornet/hornet:latest` should be `gohornet\/hornet:latest` and a peer multiaddress like `/ip4/x.x.x.x/tcp/15600/p2p/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` should be `\/ip4\/x.x.x.x\/tcp\/15600\/p2p\/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` to avoid any error occuring during running or installing hornet.

* Stop Hornet by running
```
./hornet.sh stop
```

* Start Hornet by running
```
./hornet.sh start
```

* Update Hornet to the latest version known at Docker Hub (`gohornet/hornet:latest`) by running
```
./hornet.sh update
```

## Troubleshooting

* [Autopeering](https://hornet.docs.iota.org/post_installation/peering/#autopeering) is only enabled if no peer address is provided. To check that autopeering is working correctly `node.enablePlugins` must include `"Autopeering"`.

Ensure that there are entry nodes in the `p2p.autopeering.entryNodes`. Entry nodes are encoded in `multiaddr` format.

NB: The `update` command will not update to new versions of the config files as they may contain local changes that cannot be merged with the upstream changes. If that is the case you would need to stop Hornet, merge your current config files with the config files at [https://github.com/iotaledger/one-click-tangle/blob/chrysalis/hornet-mainnet/config/config.json](https://github.com/iotaledger/one-click-tangle/blob/chrysalis/hornet-mainnet/config/config.json) and then start again Hornet. 
