# "One Click" Private Tangle Tutorial

## Introduction

IOTA [mainnet](https://docs.iota.org/docs/getting-started/1.1/networks/mainnet) and [devnet](https://docs.iota.org/docs/getting-started/1.1/networks/devnet) are public IOTA Networks where you can develop permissionless applications based on the Tangle. However, there can be situations where you would like to run a [Private IOTA Network](https://docs.iota.org/docs/compass/1.0/overview) (Private Tangle) so that only a limited set of stakeholders or nodes can participate. To support the IOTA Community working on these kind of scenarios, a set of Docker-based tools and pre-configured setups allow the deployment of a ([hornet-based](https://github.com/gohornet/hornet)) Private Tangle in **"one click"**. These tools are publicly available at the [tangle-deployment](https://github.com/iotaledger/tangle-deployment) repository. In addition, the IOTA Foundation has integrated them to be ready to be used on the [AWS Marketplace](https://aws.amazon.com/marketplace/pp/B08M4933Y3/) and, in the future, on other Cloud marketplaces.

## MVP Deployment Architecture of a Private Tangle

The figure below depicts a minimum viable deployment architecture of a Private Tangle using [Docker](https://docker.io). 

![Private Tangle Architecture](one-click-private-tangle-architecture.png "Private Tangle Architecture")

There are three main nodes identified: 

* The **Coordinator**, as described [here](https://docs.iota.org/docs/getting-started/1.1/the-tangle/the-coordinator). It emits milestones periodically and has to be bootstrapped and set up appropriately, as explained [here](https://docs.iota.org/docs/hornet/1.1/tutorials/set-up-a-private-tangle-hornet). 

* The **Spammer**. Node that sends periodically `0` value transactions to the Private Tangle, thus enabling a minimal transaction load to support transaction approval as per the IOTA protocol. 

* An initial **Regular Hornet Node**. It is exposed to the outside through the IOTA protocol (port `14265`) to be the recipient of transactions or to peer with other Nodes (through port `15600`) that can later [join](https://docs.iota.org/docs/hornet/1.1/tutorials/set-up-a-private-tangle-hornet#step-4-add-more-hornet-nodes-to-your-private-tangle) the same Private Tangle. 

These three nodes are peered among them. As our architecture is based on Docker so that each node runs within a Docker Container and all containers are attached to the same network named `private-tangle`.  

In addition, to make the Private Tangle more usable, it is very convenient to deploy a Tangle Explorer similar to the one at [https://explorer.iota.org](https://explorer.iota.org). As a result all the participants in the network will be able to browse and visualize transactions or IOTA Streams channels.  The Tangle Explorer deployment involves two different containers, one with the REST API listening at port `4000` and one with the Web Application listening at port `8082`. The Tangle Explorer also uses zeroMQ to watch what is happening on the Tangle. That is the rationale for having a connection between the Explorer's REST API Container and the Hornet Node through port `5556`. 

The Hornet Dashboard (available through HTTP port `8081`) also comes in handy as a way to monitor and ensure that your Private Tangle Nodes are in sync and performing on a good fashion.

The summary of containers that shall be running and ports exposed is as follows: 

| Component           | Container name    | Ports exposed                    |
| ------------------- | ----------------- | :------------------------------- |
| Hornet Initial Node | `node1`           | `14265`, `15600`, `8081`, `5556` |
| Coordinator         | `coo`             | `15600`                          |
| Spammer             | `spammer`         | `14265`, `15600`                 |
| Explorer API        | `explorer-api`    | `4000`                           |
| Explorer Web App    | `explorer-webapp` | `80`                             |

The summary of published services is as follows: 

| Service          | Container name    | Port    |
| ---------------- | ----------------- | ------- |
| IOTA Protocol    | `node1`           | `14265` |
| IOTA Peering     | `node1`           | `15600` |
| Dashboard        | `node1`           | `8081`  |
| Explorer API     | `explorer-api`    | `4000`  |
| Explorer Web App | `explorer-webapp` | `8082`  |


The deployment architecture described above can be easily transitioned to production-ready by incorporating a reverse proxy leveraging [NGINX](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/#). As a result the amount of ports exposed to the outside world can be reduced or load balancing between the nodes of your Private Tangle can be achieved. IOTA Foundation intends to provide automatic, "one click" deployment of these kind of enhanced architectures in the next version of this software. 

To support the deployment of a Private Tangle the IOTA Community has developed a set of shell scripts and configuration templates to make it easier to deploy a (Docker based) Private Tangle with the architecture described above. These scripts automate the steps described [here](https://docs.iota.org/docs/hornet/1.1/tutorials/set-up-a-private-tangle-hornet#step-4-add-more-hornet-nodes-to-your-private-tangle). You can also customize the [default configuration files](./hornet-private-net/config), for instance if you want to enable extra [Hornet plugins](https://docs.iota.org/docs/hornet/1.1/overview). 

But now let's see how we can launch our Private Tangle via a "single click". We have two options. Through the [AWS Marketplace](https://aws.amazon.com/marketplace/pp/B08M4933Y3/) or through any [Docker-enabled machine](#one-click-private-tangle-deployment-on-any-docker-enabled-machine). 

## "One Click" Private Tangle on AWS

To materialize on AWS the deployment architecture described above, go to the AWS Marketplace and install this [product](https://aws.amazon.com/marketplace/pp/B08M4933Y3/) and follow the [instructions](./README_AWS.md). That's it!. 

Behind the scenes, the process will launch all the Docker containers (through docker-compose), create a seed for the Coordinator, generate the Merkle Tree, configure the Coordinator Address for the initial node, generate an initial IOTA Address holding all IOTAs, a seed for our Nodes, etc i.e. our [deployment architecture](#mvp-deployment-architecture-of-a-private-tangle) and all the steps described [here](https://docs.iota.org/docs/hornet/1.1/tutorials/set-up-a-private-tangle-hornet), but **fully automated**, in "one click"!.

The Private Tangle installed will have a Merkle Tree of Depth `24` and could take half a day to be generated. See also a basic explanation of [Merkle Tree Generation](#merkle-tree-depth). 

The Parameters of this "one click" installation are as follows (further details can be found at [here](./hornet-private-net/config):

* Merkle Treep Depth: `24`.
* Coordinator Milestones Period: `60` seconds. 
* MWM:`9`.
* Coordinator Security Level: `2`.
* Spammer Settings, check [these lines of code](https://github.com/iotaledger/tangle-deployment/blob/master/hornet-private-net/config/config-spammer.json#L72).

Further instructions for AWS deployments can be found [here](./README_AWS.md). If you want to know lower-level details of the AWS installation, how to do it yourself in any Docker-enabled VM and what happens under the scenes, please continue reading. 

## "One Click" Private Tangle on any Docker-enabled VM

### Prerequisites

You need [Docker](https://www.docker.com) and Docker Compose. **Docker Compose** is a tool for defining and running multi-container Docker applications. A series [YAML files](./docker-compose.yaml) are used to configure the required services. This means all container services can be brought up in a single command. Docker Compose is installed by default as part of Docker for Windows and Docker for Mac, however Linux users will need to follow the instructions found [here](https://docs.docker.com/compose/install/)

You can check your current **Docker** and **Docker Compose** versions using the following commands:

```console
docker-compose -v
docker version
```

Please ensure that you are using Docker version `18.03` or higher and Docker Compose `1.21` or higher and upgrade if
necessary.

### Clone the script Repository

To start with, you need to clone the [tangle-deployment](https://github.com/iotaledger/tangle-deployment) repository as follows:

```console
git clone https://github.com/iotaledger/tangle-deployment
```

Then, ensure that the `private-tangle.sh` script has execution permissions:

```console
cd tangle-deployment/hornet-private-net
chmod +x ./private-tangle-sh
```

### Merkle Tree Depth

First of all, you need to think about the depth of the [Merkle Tree](https://docs.iota.org/docs/getting-started/1.1/cryptography/merkle-tree-address) for your Private Tangle's Coordinator. The depth of the Merkle Tree determines the number of milestones the Coordinator will be able to emit. However, deeper Merkle Trees lead to longer generation times. Nonetheless, you should not worry about it as this is done one time. In addition, our scripts provide the ability to monitor the Merkle Tree generation process through a Web endpoint. 

Now, let's make a small calculation. If we decide to build a Merkle Tree of Depth `20` we could generate `2**20` milestones i.e. `1048576`  milestones. If we set up our Coordinator to emit a milestone every minute (as it is configured by default), we would have `60` milestones per hour and `1440` milestones per day. If we divide `1048576` by `1440` we would have milestones for nearly `2` years. After that time, we would need to regenerate a new Merkle Tree and update all configurations. 

The duration of the calculation of the Merkle Tree for a depth of `20` can be around `2` hours on a usual developer's laptop. The Merkle Tree generated for AWS Deployments is `24` (you have milestones for 5 years) and can its generation can take half a day. But that is done once for all. 

### Run your Private Tangle

In this tutorial we will use a Merkle Tree of Depth `16`, that just takes some minutes to be built. To start our Private Tangle through the command line:

```console
./private-tangle.sh start 16 30
```

The first parameter is the depth of the Merkle Tree and the second parameter is the amount of time (in seconds) to wait for the Coordinator bootstrap step. That step allows the Coordinator to bootstrap by emitting its first milestone as detailed [here](https://docs.iota.org/docs/hornet/1.1/tutorials/set-up-a-private-tangle-hornet#step-3-run-your-private-tangle). 

Behind the scenes our process will create a seed for the Coordinator, an initial IOTA Address holding all IOTAs, a seed for our Nodes, etc i.e. all the steps described [here](https://docs.iota.org/docs/hornet/1.1/tutorials/set-up-a-private-tangle-hornet),  but **fully automated**. In order to monitor the Merkle Tree Generation process, the script run a Web endpoint that you can use to monitor the status through your favorite browser, at `http://localhost:9000/merkle-tree-generation.log.html`. (The page refreshes automatically). 

After the process finishes you should see the following docker containers up and running:

```console
docker ps -a
```

```console
c1958a2918d4        gohornet/hornet              "/sbin/tini -- /app/…"   2 days ago          Up 2 days           0.0.0.0:8081->8081/tcp, 0.0.0.0:14265->14265/tcp, 5556/tcp, 0.0.0.0:15600->15600/tcp   node1
21f7b4a96ccf        gohornet/hornet              "/sbin/tini -- /app/…"   2 days ago          Up 2 days           14265/tcp, 15600/tcp                                                                   spammer
66b218cb08e1        gohornet/hornet              "/sbin/tini -- /app/…"   2 days ago          Up 2 days           15600/tcp                                                                              coo
8a3b1e8f3e9b        nginx                        "/docker-entrypoint.…"   3 days ago          Up 3 days           0.0.0.0:9000->80/tcp                                                                   nginx
```

At this moment you no longer need the NGINX container that allows to monitor the Merkle Tree generation so it will be safe to remove it:

```console
docker-compose stop nginx
```

On the other hand the following files should have been created for you:

* `merkle-tree.addr`. The public address of the Coordinator. 
* `coordinator.seed`. The seed of the coordinator. Keep it safe! 
* `node.seed`. The seed of the initial Hornet Bode. Keep it safe!
* `snapshots/private-tangle/snapshot.csv` The initial Private Tangle snapshot. It contains just one IOTA address that is holding all IOTAs. 

If you browse to `http://localhost:8081` you can play with the Hornet Dashboard. 

You can find the Tangle database files at `db/private-tangle`. 

### Tangle Explorer

Once we have our Private Tangle up and running, we can install and run a Tangle Explorer as follows:  

```console
cd ../explorer
tangle-explorer start ../hornet-private-net
```

Automatically the Tangle Explorer will be configured with the parameters of our Private Tangle, and once the docker build process finishes you should find the following additional docker containers up and running:

```console
dd4bcad67c5e        iotaledger/explorer-webapp   "docker-entrypoint.s…"   2 days ago          Up 2 days           0.0.0.0:8082->80/tcp                                                                   explorer-webapp
7c22023f4316        iotaledger/explorer-api      "docker-entrypoint.s…"   2 days ago          Up 2 days           0.0.0.0:4000->4000/tcp                                                                 explorer-api
```

You can now get access to the Tangle Explorer through `http://localhost:8082`. 

## Limitations and Troubleshooting

Currently launching a new installation will blindly remove all existing data, so you have to be careful. Next version of the scripts will allow to stop, restart and update all the software artifacts.

For Mac OS there is an issue with permissions and you may need to comment [this line of code](https://github.com/iotaledger/tangle-deployment/blob/master/hornet-private-net/private-tangle.sh#L106)
