# Private Tangle Deployment Tutorial

## Introduction

IOTA [mainnet]() and [devnet]() are the public IOTA Networks where you can develop permissionless applications based on the Tangle. However, there can be situations where you would like to run a Private IOTA Network so that only a limited set of stakeholders or Nodes can participate and make or explore transactions on the network. IOTA Foundation is committed to support the Community in enjoying the advantages of the IOTA protocol also in these kind of deployment scenarios. In fact a set of tools and pre-configured setups allow the deployment of a Private Tangle in "one click". Those tools are publicly available at the [tangle-deployment](https://github.com/iotaledger/tangle-deployment) repository on Github. In addition, IOTA Foundation has integrated these scripts to be ready to be used on the AWS Marketplace and, in the future, with the help of our community, in other Cloud marketplaces.

## Target Architecture of a Private Tangle

In the figure below you can see a production-ready target architecture of a Private Tangle Deployment. 

There are three main nodes identified: 

* The **Coordinator**, as described [here], docker container hostname `coo`. The Coordinator emits milestones periodically and has to bootstrapped and set up appropriately, as explained below. 

* The **Spammer**, docker container hostname `spammer`,  node that sends 0 value transactions to the Private Tangle periodically, thus enabling a minimal transaction load to support transaction approval as per IOTA protocol. 

* An initial **Regular Hornet Node**, (the initial Hornet node, docker container hostname `node1`) that will be exposed to the outside through the IOTA protocol (port `14265`) to be the recipient of transactions or to peer with other Nodes (through port `15600`) that can later join the same Private Tangle. 

These three nodes are peered between them. Our architecture is based on Docker so that each node runs within a Docker Container and all container are attached to the same network named `private-tangle`.  

In addition, to make the Private Tangle more usable, it is convenient to deploy a Tangle Explorer similar to the one at [https://explorer.iota.org](https://explorer.iota.org). As a result all the participants in the network will be able to browse transactions, streams channels or visualize the Tangle.  The Tangle Explorer deployment implies two different containers, one with the REST API listening at port `4000` and one with the Web Application listening at port `8082`. The Tangle Explorer also uses zeroMQ to watch what is happening on the Tangle and that is why a connection between the Explorer's REST API Container and the Node  through port `` is needed. 

The Hornet Dashboard (available through HTTP port `8081`) also comes in handy as a way to monitor that your Private Tangle Nodes are in sync and performing on a good fashion.

The Architecture described above can be enhanced with a reverse proxy leveraging [NGINX](). As a result the amount of ports exposed to the outside world can be reduced or load balancing between the nodes of your Tangle can be achieved. IOTA Foundation plans to provide automatic deployment of those kind of enhanced architectures as well in the near future. 

## Deploying a Private Tangle on any Docker-enabled machine

To support the deployment of a Private Tangle IOTA Foundation has developed a set of shell scripts and configuration templates to make it easier to deploy a Private Tangle with the setup described above. As it has been mentioned it relies on Docker technology. 

To start with you need to clone the `tangle-deployment` repository as follows

```shell
git clone
```

Then ensure that the private-tangle.sh file has write permissions. 

Then you need to run 

By default the Coordinator emits milestones xx per minute. 

You can monitor progress of the Merkle Tree Generation at 

After the process has finished you should see the following docker containers up and running as follows: 

### Explorer Deployment

The next step is to deploy the Explorer the main thing is to craft a network configuration file

## Deploying a Private Tangle on a Public Cloud

IOTA Foundation. Specific instructions for AWS can be found here. 

## Limitations and Trouebleshooting

