# Instructions to Set up a Private Tangle on AWS

On the AWS Marketplace you can find the Private Tangle product [here](https://aws.amazon.com/marketplace/pp/B095WQQTNG). 

1. In the "Security Group Settings" before you launch the instance please click "Create New Based On Seller Settings" or make sure that ports `8081` (Hornet's dashboard), `14265` (IOTA protocol), `8082` (Tangle Explorer Frontend) and `4000` (Tangle Explorer API) are exposed to the Internet. Additionally, if you want to peer your regular Hornet Node with nodes in other external machines you will need to expose port `15600` (peering port). 

2. Run this script: `/bin/install-private-tangle.sh`

3. The bootstrap and installation process will be initiated. 

4. Afterwards, the Private Tangle should be up and running. You can get access to the node1's Private Tangle dashboard at `http://<aws_dns_name>:8081` and from such dashboard you will be able to check the status of "node1" and the rest of peered nodes (the coordinator, and the spammer). Also you can get access to the Tangle Explorer through `http://<aws_dns_name>:8082`.

7. Please bear in mind, that it can take a little while for the nodes to be in synced state. 

8. Please note that the Private Tangle related config files are located at `one-click-tangle/hornet-private-net/config/`. The Tangle DB files are located at `db/private-tangle`. 


# Sanity Checks

Once the process finishes you should see at least the following docker containers up and running:

```console
docker ps -a
```

```console
CONTAINER ID   IMAGE                        COMMAND                  CREATED         STATUS         PORTS      NAMES
07bbdbb89201   iotaledger/explorer-webapp   "docker-entrypoint.s…"   5 seconds ago   Up 2 seconds   0.0.0.0:8082->80/tcp explorer-webapp
c68ca2deec5c   iotaledger/explorer-api      "docker-entrypoint.s…"   8 seconds ago   Up 5 seconds   0.0.0.0:4000->4000/tcp      explorer-api
f82a28f90c71   gohornet/hornet:1.0.2-rc1    "/app/hornet"            6 minutes ago   Up 6 minutes   0.0.0.0:1883->1883/tcp, 0.0.0.0:8081->8081/tcp, 0.0.0.0:14265->14265/tcp, 14626/udp, 15600/tcp   node1
e0e8b6a44239   gohornet/hornet:1.0.2-rc1    "/app/hornet"            6 minutes ago   Up 6 minutes   8081/tcp, 14265/tcp, 15600/tcp, 14626/udp  spammer
44fcdfd7cc5f   gohornet/hornet:1.0.2-rc1    "/app/hornet"            6 minutes ago   Up 6 minutes   8081/tcp, 14265/tcp, 15600/tcp, 14626/udp coo
```

The three Hornet nodes, the Explorer (API and Web App). 

# Private Tangle Cryptographic materials, identities and addresses:

Once the process finishes the following files should have been created for you:

* `coo.identity.txt`. The P2P identity of the Coordinator. 
* `node1.identity.txt`. The P2P identity of the node1. 
* `spammer.identity.txt`. The P2P identity of the Spammer. 

The P2P identities can be used to peer these Nodes with other Nodes. 

* `key-pair.txt`. The Ed25519 Key pair corresponding to the address that holds all the IOTAs. 
* `address.txt`. The address that holds all IOTAs initially. 

* `coo-milestones-key-pair.txt`. The Ed25519 key pair used by the Coordinator to sign milestones. Keep it safe!
* `coo-milestones-public-key.txt`. The Ed25519 public key that can be used to verify Coordinator's milestones. 

* `snapshots/private-tangle/full_snapshot.bin` The initial Private Tangle snapshot. It contains just one IOTA address that is holding all IOTAs. 
