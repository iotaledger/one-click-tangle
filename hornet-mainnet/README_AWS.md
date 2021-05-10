# Instructions to Set up a Chrysalis Hornet Node on AWS

On the AWS Marketplace you can find the Hornet product [here](https://aws.amazon.com/marketplace/TBD). 

1. In the "Security Group Settings" before you launch the instance please click "Create New Based On Seller Settings" or make sure that ports, `8081` (Hornet's dashboard), `14265` (IOTA API), `15600` (IOTA Gossip Protocol) are exposed to the Internet. 

2. Run this script: `/bin/install-hornet.sh`. 

NB: Optionally you can pass the  `-p` option to specify a multi-address peer as detailed [here](https://hornet.docs.iota.org/post_installation/peering.html). 

If you want to install a different Hornet Docker image / version than `gohornet/hornet:latest` you can do so by passing the `-i` option. 

3. The bootstrap and installation process will be initiated. 

4. Please note that the Hornet related config files are located at `one-click-tangle/hornet-mainnet/config/`. The Tangle DB files are located at `db/mainnet`. 

# Dashboard

You can get access to the Hornet dashboard by opening on your Web Browser the following page: `http://<your_ec2_machine_address>:8081`. 

The username and password of the dashboard application is `admin`. You can set a new password by executing

```console
docker-compose run --rm hornet tool pwdhash 
```
and then edit the `config/config.json` file, changing the password hash and salt by the new values (under the  `dashboard` section). Afterwards you will need to restart Hornet by running: 

```console
./hornet.sh stop
./hornet.sh start
```

# Peers 

You can add new peers when installing or later, by login into the dashboard, and then through the "Peers" menu. 

NB: Another option is to add a peer through the `config/peering.json` file as described [here](https://hornet.docs.iota.org/post_installation/peering.html). In that case you will need to first stop Hornet, then edit the file and finally start Hornet again. 

# Sanity Checks

Once the process finishes you should see at least the following docker containers up and running:

```console
docker ps -a
```

```console
CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS          PORTS                                                                                             NAMES
eec6d1dd21c5   gohornet/hornet:latest             "/app/hornet"            10 minutes ago   Up 10 minutes   0.0.0.0:8081->8081/tcp, 0.0.0.0:14265->14265/tcp, 5556/tcp, 0.0.0.0:15600->15600/tcp, 14626/udp   hornet
```

# Node Operations

You can update Hornet to the latest version by running:

```console
./hornet.sh update
```

You can stop Hornet by running:

```console
./hornet.sh stop
```

You can reinstall Hornet (you will lose all data and configurations) by running:

```console
./hornet.sh install
```
