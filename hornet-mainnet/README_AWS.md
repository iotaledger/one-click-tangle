# Instructions to Set up a Chrysalis Hornet Node on AWS

On the AWS Marketplace you can find the Hornet product [here](https://aws.amazon.com/marketplace/pp/B095HWF6JZ). 

1. In the "Security Group Settings" before you launch the instance please click "Create New Based On Seller Settings" or make sure that ports, `8081` (Hornet's dashboard), `14265` (IOTA API), `15600` (IOTA Gossip Protocol), `14626` (Autopeering) are exposed to the Internet. 

2. Run this script: `/bin/install-hornet.sh`. 

NB: Optionally you can pass the  `-p` option to specify a multi-address peer as detailed [here](https://hornet.docs.iota.org/post_installation/peering.html). 

If you want to install a different Hornet Docker image / version than `gohornet/hornet:latest` you can do so by passing the `-i` option. 

3. The bootstrap and installation process will be initiated. 

4. Please note that the Hornet related config files are located at `one-click-tangle/hornet-mainnet/config/`. The Tangle DB files are located at `db/mainnet`. 

## Dashboard

You can get access to the Hornet dashboard by opening on your Web Browser the following page: `http://<your_ec2_machine_address>:8081`. 

The username and password of the dashboard application is `admin`. You can set a new password by executing

```console
docker-compose run --rm hornet tool pwd-hash 
```
and then edit the `config/config.json` file, changing the password hash and salt by the new values (under the  `dashboard` section). Afterwards you will need to restart Hornet by running: 

```console
./hornet.sh stop
./hornet.sh start
```

## Peering

The identity of your node is automatically generated and configured. You can find your Node P2P keys and identity in the `p2pidentity.txt` file. 

You can add new peers when installing (`-p` option), or later, by login into the dashboard, and then through the "Peers" menu. When installing, if no peer is specified then [autopeering](https://hornet.docs.iota.org/post_installation/peering/#autopeering) will be enabled, and your peers will be automatically discovered and configured. 

NB: Another option is to add a peer through the `config/peering.json` file as described [here](https://hornet.docs.iota.org/post_installation/peering.html). In that case you will need to first stop Hornet, then edit the file and finally start Hornet again. 

## Sanity Checks

Once the process finishes you should see at least the following docker containers up and running:

```console
docker ps -a
```

```console
CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS          PORTS                                                                                             NAMES
eec6d1dd21c5   gohornet/hornet:latest             "/app/hornet"            10 minutes ago   Up 10 minutes   0.0.0.0:8081->8081/tcp, 0.0.0.0:14265->14265/tcp, 5556/tcp, 0.0.0.0:15600->15600/tcp, 14626/udp   hornet
```

## Node Operations

You can update Hornet to the latest version known by DockerHub by running:

```console
./hornet.sh update
```

NB: The `update` command will not update to new versions of the config files as they may contain local changes that cannot be merged with the upstream changes. If that is the case you would need to stop Hornet, merge your current config files with the config files at [https://github.com/iotaledger/one-click-tangle/blob/chrysalis/hornet-mainnet/config/config.json](https://github.com/iotaledger/one-click-tangle/blob/chrysalis/hornet-mainnet/config/config.json) and then start again Hornet.

You can stop Hornet by running:

```console
./hornet.sh stop
```

You can reinstall Hornet (**you will lose all data and configurations**) by running:

```console
./hornet.sh install
```
