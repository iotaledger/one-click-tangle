# Instructions to Set up a Private Tangle on AWS

On the AWS Marketplace you can find the Private Tangle product [here](https://aws.amazon.com/marketplace/pp/B08M4933Y3). 

1. In the "Security Group Settings" before you launch the instance please click "Create New Based On Seller Settings" or make sure that ports, `9000` (NGINX for monitoring Merkle Tree Generation), `8081` (Hornet's dashboard), `14265` (IOTA protocol), `8082` (Tangle Explorer Frontend) and `4000` (Tangle Explorer API) are exposed to the Internet. 

2. Run this script: `/bin/install-private-tangle.sh`

3. The bootstrap and installation process will be initiated in the background. At any time you can execute `tail -f nohup.out` to watch what is happening. 

4. The IOTA's Coordinator bootstrapping can take around 14 hours, as a Merkle Tree (a cryptographic data structure) has to be calculated for milestones. At anytime you can launch a Web browser to `http://<aws_dns_name>:9000/merkle-tree-generation.log.html` to watch the progress of the Merkle Tree Generation. 

5. Once the Merkle Tree has been generated, the process listening on port `9000` (a docker container with NGINX) can be stopped by running `docker-compose stop nginx`. Therefore, at this stage, in the security policies section, the port `9000` can also be removed from inbound traffic. 

6. Afterwards, the Private Tangle should be up and running. You can get access to the node1's Private Tangle dashboard at `http://<aws_dns_name>:8081` and from such dashboard you will be able to check the status of "node1" and the rest of peered nodes (the coordinator, and the spammer). Also you can get access to the Tangle Explorer through `http://<aws_dns_name>:8082`.

7. Please bear in mind, that it can take a little while for the nodes to be in synced state. 

8. Please note that the Private Tangle related config files are located at `IOTA-Tangle-Node-Deployment/hornet-private-net/config/`. The Tangle DB files are located at `db/private-tangle`. 

# Sanity Checks

After the process finishes you should see at least the following docker containers up and running:

```console
docker ps -a
```

```console
dd4bcad67c5e        iotaledger/explorer-webapp   "docker-entrypoint.s…"   2 days ago          Up 2 days           0.0.0.0:8082->80/tcp                                                                   explorer-webapp
7c22023f4316        iotaledger/explorer-api      "docker-entrypoint.s…"   2 days ago          Up 2 days           0.0.0.0:4000->4000/tcp                                                                 explorer-api
c1958a2918d4        gohornet/hornet              "/sbin/tini -- /app/…"   2 days ago          Up 2 days           0.0.0.0:8081->8081/tcp, 0.0.0.0:14265->14265/tcp, 5556/tcp, 0.0.0.0:15600->15600/tcp   node1
21f7b4a96ccf        gohornet/hornet              "/sbin/tini -- /app/…"   2 days ago          Up 2 days           14265/tcp, 15600/tcp                                                                   spammer
66b218cb08e1        gohornet/hornet              "/sbin/tini -- /app/…"   2 days ago          Up 2 days           15600/tcp                                                                              coo
8a3b1e8f3e9b        nginx                        "/docker-entrypoint.…"   3 days ago          Up 3 days           0.0.0.0:9000->80/tcp
```

The three Hornet nodes, the Explorer (API and Web App) and NGINX (remember that you can stop it as no longer needed). 

# Private Tangle Seeds and Addresses

After the launching process finishes the following files should have been created for you:

* `merkle-tree.addr`. The public address of the Coordinator. 
* `coordinator.seed`. The seed of the coordinator. Keep it safe! 
* `node.seed`. The seed of the initial Hornet Bode. Keep it safe!
* `snapshots/private-tangle/snapshot.csv` The initial Private Tangle snapshot. It contains just one IOTA address that is holding all IOTAs. 
