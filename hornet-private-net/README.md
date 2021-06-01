# Private Tangle Setup using Hornet

You can also use these scripts under the [AWS Marketplace](./README_AWS.md)

## Usage

* Make the the bash script executable by running
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

* Update all the containers images to the latest version specified on the `docker-compose.yaml` file. 

```
./private-tangle.sh update
```
