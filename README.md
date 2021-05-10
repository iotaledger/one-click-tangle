<h2 align="center">One Click Tangle</h2>

<p align="center">
  <a href="https://discord.iota.org/" style="text-decoration:none;"><img src="https://img.shields.io/badge/Discord-9cf.svg?logo=discord" alt="Discord"></a>
    <a href="https://iota.stackexchange.com/" style="text-decoration:none;"><img src="https://img.shields.io/badge/StackExchange-9cf.svg?logo=stackexchange" alt="StackExchange"></a>
    <a href="https://github.com/iotaledger/one-click-tangle/blob/master/LICENSE" style="text-decoration:none;"><img src="https://img.shields.io/github/license/iotaledger/one-click-tangle.svg" alt="MIT license"></a>
</p>
      
<p align="center">
  <a href="#about">About</a> ◈
  <a href="#prerequisites">Prerequisites</a> ◈
  <a href="#getting-started">Getting started</a> ◈
  <a href="#supporting-the-project">Supporting the project</a> ◈
  <a href="#joining-the-discussion">Joining the discussion</a> 
</p>

---

## About

This repository is where the IOTA Foundation hosts the open-source code for deploying IOTA Nodes and Networks "in one click".

The code is composed of:

- [**`hornet`:**](hornet-mainnet/README.md) Script to deploy a new Hornet Node. 
- [**`private-tangle`:**](hornet-private-net/README.md) Script to deploy a new Private Tangle composed of Coordinator, Spammer and one regular Hornet Node. 
- [**`explorer`:**](explorer/README.md) Script to deploy a new [Tangle Explorer](https://github.com/iotaledger/explorer).
- [**`bootstrap`:**](bootstrap/README.md) Scripts that support full IOTA's Private Tangle Deployment on the [AWS Marketplace](https://aws.amazon.com/marketplace/pp/B08M4933Y3).

This is beta software, so there may be issues.
Please report any issues in our [issue tracker](https://github.com/iotaledger/one-click-tangle/issues/new).

Related Community Projects: [Hornet Playbook](https://github.com/nuriel77/hornet-playbook)

## Prerequisites

To execute these scripts you need [Docker](https://www.docker.com) and Docker Compose. **Docker Compose** is a tool for defining and running multi-container Docker applications. A series [YAML files](./docker-compose.yaml) are used to configure the required services. This means all container services can be brought up in a single command. Docker Compose is installed by default as part of Docker for Windows and Docker for Mac, however Linux users will need to follow the instructions found [here](https://docs.docker.com/compose/install/)

You can check your current **Docker** and **Docker Compose** versions using the following commands:

```console
docker-compose -v
docker version
```

Please ensure that you are using Docker version `18.03` or higher and Docker Compose `1.21` or higher and upgrade if
necessary.

## Getting started

### Getting started - Hornet

First you need to clone the Repository

```
git clone https://github.com/iotaledger/one-click-tangle
```

Afterwards you can install a Hornet Node by

```
cd hornet-mainnet
chmod +x hornet.sh
./hornet.sh install
```

### Getting started - Private Tangle

First you need to clone the Repository

```
git clone https://github.com/iotaledger/one-click-tangle
```

Afterwards you can install a Private Tangle with Merkle Tree Depth of `16` by

```
cd hornet-private-net
chmod +x private-tangle.sh
./private-tangle.sh start 16
```

The depth of the Merkle Tree determines how many milestones the Coordinator can issue. For instance, with a Merkle Tree of depth `16` and a Coordinator issuing a confirmation milestone every `10` seconds you could run a Tangle for just `7` days. The deeper the Merkle Tree the longer it will take to create it and bootstrap the Private Tangle. 

You may also want to [deploy a Tangle Explorer](./explorer). 

Additional instructions can be found on this [tutorial](https://docs.iota.org/docs/hornet/1.1/tutorials/one-click-private-tangle). 

## Supporting the project

If this project has been useful to you and you feel like contributing, consider submitting a [bug report](https://github.com/iotaledger/one-click-tangle/issues/new), [feature request](https://github.com/iotaledger/one-click-tangle/issues/new) or a [pull request](https://github.com/iotaledger/one-click-tangle/pulls/).

See our [contributing guidelines](.github/CONTRIBUTING.md) for more information.

## Joining the discussion

If you want to get involved in the community, need help with getting set up, have any issues or just want to discuss IOTA, Distributed Registry Technology (DRT), and IoT with other people, feel free to join our [Discord](https://discord.iota.org/).
