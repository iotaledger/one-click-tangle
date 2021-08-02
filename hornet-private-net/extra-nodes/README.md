# Private Tangle Extra Nodes

You can also use these scripts under the [AWS Marketplace](./README_AWS.md).

Once you have an up and running Private Tangle, this utility allows adding extra Hornet nodes. 

## Usage

* Make the the bash script executable by running

```
chmod +x private-hornet.sh
```

* Install a new Hornet Node as part of a Private Tangle under the same local installation

*Warning: It destroys previous data.* 

```
./private-hornet.sh install "node2:14266:15601:8082"
```

The first parameter is a node description string. The node description string has different 
fields separated by a colon (`:`). It contains the name of your node and, optionally, 
the ports corresponding to the *API endpoint*, the *peering endpoint* and the *dashboard endpoint*. 

 * Install a new Hornet Node passing the Private Tangle parameters on the command line

*Warning: It destroys previous data.* 

```
./private-hornet.sh install "node2"  61d564e6b20c060566110f1f0b59bb0569bd93315070f2ceaa33aba0be7f086b "\/dns\/my-node\/tcp\/15600\/p2p\/12D3KooWSXdWBH7NpzSMzsMnDivTgi6E5wA7awwHpcoJwXG9wUdx" "/my-snapshots/private-tangle/full_snapshot.bin"
```

The first parameter is the node description string as explained above. The second parameter is *Coordinator address*. 
The third parameter is the *peer multi-address* of the Node you are going to peer with. The last parameter is the *snapshot* that will be used to sync up the ledger state. 

* Stop your Node by running 

```
./private-hornet.sh stop node2
```

* Start your node by running

```
./private-hornet.sh start node2
```

* Update the container image to the latest version. 

```
./private-hornet.sh update node2
```
