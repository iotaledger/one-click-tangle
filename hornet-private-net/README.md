# Private Tangle Setup using Hornet

You can also use these scripts under the [AWS Marketplace](./README_AWS.md)

## Usage

* Make the bash script executable by running
```
chmod +x private-tangle.sh
```

* Install a new Tangle with Coordinator, Spammer and 1 Node

*Warning: It destroys previous data.* 

```
./private-tangle.sh install <coo_bootstrap_wait_time>
```

The parameter `coo_bootstrap_wait_time` is optional (default is `10` seconds) and denotes the time in seconds to wait for the coordinator to bootstrap.

* Stop all the containers by running 

```
./private-tangle.sh stop
```

* Start all the containers by running 

```
./private-tangle.sh start
```

* Update all the containers images to the latest version specified on the `docker-compose.yml` file. 

```
./private-tangle.sh update
```

NB: The `update` command will not update to new versions of the config files as they may contain local changes that cannot be merged with the upstream changes. If that is the case you would need to stop the Private Tangle, merge your current config files with the config files at [https://github.com/iotaledger/one-click-tangle/blob/chrysalis/hornet-private-net/config](https://github.com/iotaledger/one-click-tangle/blob/chrysalis/hornet-private-net/config) and then start again your Private Tangle.


* Add extra Nodes to your Private Tangle

Go to the `extra-nodes` folder and follow the recipe [here](./extra-nodes/README.md). 

## Notes on IOTA Frameworks

If you want to use [IOTA Identity](https://github.com/identity.rs) on your Private Tangle you can do it by assigning the network identifier `tangle` to the DID method used, for instance `did:iota:tangle:F7PAPm2LqngmmN2uu3DSmHAvu74zA5f8c7c9R75qnMkG`. A DID generation Rust example can be found [here](https://github.com/iotaledger/identity.rs/blob/dev/examples/low-level-api/private_tangle.rs). 

Note: If you install the Tangle Explorer the Identity Resolver will be enabled by default. The URL to inspect your generated DIDs will be typically of the form `http://localhost:8082/tangle/identity-resolver/{DID}`, for instance `http://localhost:8082/tangle/identity-resolver/did:iota:tangle:F7PAPm2LqngmmN2uu3DSmHAvu74zA5f8c7c9R75qnMkG`
