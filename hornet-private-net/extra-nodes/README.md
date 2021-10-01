# Private Tangle Extra Nodes

You can also use these scripts under the [AWS Marketplace](../README_AWS.md).

Once you have an up and running Private Tangle, this utility allows adding extra Hornet nodes. 

## Usage

* Make the bash script executable by running

```
chmod +x private-hornet.sh
```

* Install a new Hornet Node as part of a Private Tangle under the same local installation

*Warning: If there is an existing Node with the same name, it destroys previous data.* 

```
./private-hornet.sh install "my-node:14266:15601:8082"
```

The first parameter is a Node connection string. Such string has different 
fields separated by a colon (`:`). The first field is the (container and host) name 
of your Node and, at installation time, it can be followed, optionally, by the TCP port 
numbers (exposed on the host) corresponding to 
the *API endpoint*, the *gossip peering endpoint* and the *dashboard endpoint*. 

*Note*: If no port numbers are provided, i.e. only the container name is supplied, no ports will be exposed to the host. 

*Note*: You can omit some of the ports but the separator `:` has to be kept, for instance, if you just only want to  expose the dashboard port to the host you can run:

```
./private-hornet.sh install "my-node:::8082"
```

*Note*: By default your Node will be peered using the default autopeering Entry Node provided off-the-shelf by the Private Tangle installation. 

 * Install a new Hornet Node passing the Private Tangle parameters on the command line

*Warning: If there is an existing Node with the same name, it destroys previous data.* 

```
./private-hornet.sh install "my-node"  
61d564e6b20c060566110f1f0b59bb0569bd93315070f2ceaa33aba0be7f086b 
"\/dns\/my-other-node\/tcp\/15600\/p2p\/12D3KooWSXdWBH7NpzSMzsMnDivTgi6E5wA7awwHpcoJwXG9wUdx" 
"/my-snapshots/private-tangle/full_snapshot.bin"
```

The first parameter is the Node connection string as explained above. The second parameter is the 
*Coordinator's public key*. The third parameter can be either  a *peer multi-address* of the Node you are going 
to peer with or an entry node for autopeering, for instance, `\/dns\/node-autopeering\/udp\/14626\/autopeering\/14bPxgiL7ALdQd9Qmb3z4uwCsX4M7PGPeouNaVPx45ax`. 
The last parameter is the *snapshot* file that will be used to sync up an initial ledger state. 

* Stop an existing Node by running 

```
./private-hornet.sh stop my-node
```

* Start an existing Node by running

```
./private-hornet.sh start my-node
```

* Update an existing Node's container image to the latest version. 

```
./private-hornet.sh update my-node
```
