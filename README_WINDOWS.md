# Instructions to Set up a Private Tangle on Windows 10

1. Install [Docker for Windows](https://docs.docker.com/desktop/windows/install)
- Make sure to also install the required Windows components for WSL 2 ([Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about))

2. After the installation you can check your **Docker** (`>=18.03`) and **Docker Compose** (`>=1.21`) versions using the following CMD commands
```console
docker -v
docker-compose -v
```

3. Install Ubuntu distribution using the following CMD commands step by step (list available distributions / install Ubuntu / check version)
```console
wsl --list --online
wsl --install --distribution Ubuntu
wsl -l -v
```

4. Make Ubuntu your default WSL distribution by using the following CMD commands (set default distribution / check new default)
```console
wsl --set-default Ubuntu
wsl --list
```

5. Docker Desktop Settings
- Enable WSL integration with new Ubuntu distribution (*Settings > Resources > WSL INTEGRATION*)
- Make sure Docker Compose v2 is <ins>deactivated</ins> (*Settings>General*)

6. Clone [one-click-tangle](https://github.com/iotaledger/one-click-tangle) repository with the following CMD commands
```console
git clone https://github.com/iotaledger/one-click-tangle
cd one-click-tangle
```

7. Now you can install different components available in one-click-tangle repo
\
    a) hornet-private-net (private tangle)
    - Run Ubuntu as <ins>administrator</ins>
    - Navigate to <ins>your</ins> repo path with the following Linux command
    ```console
        cd /mnt/<repo_path>/one-click-tangle/hornet-private-net/
    ```
    - Trigger shell script with 30 seconds to wait for the Coordinator bootstrap step with the following Linux command (This will set up several docker containers)
    ```console
        ./private-tangle.sh install 30
    ```
    Interact with private tangle as described in this [README](https://github.com/iotaledger/one-click-tangle/blob/a8ff9269b76fd7f3eb1e4ef95426ca8fc263e52b/hornet-private-net/README.md)
\
    b) hornet-mainnet (Chrysalis mainnet node)
    - Run Ubuntu as <ins>administrator</ins>
    - Navigate to <ins>your</ins> repo path with the following Linux command
    ```console
        cd /mnt/<repo_path>/one-click-tangle/hornet-mainnet/
    ```
    - Trigger shell script to set up hornet mainnet node
    ```console
        ./hornet.sh install
    ```
    Interact with mainnet node as described in this [README](https://github.com/iotaledger/one-click-tangle/blob/chrysalis/hornet-mainnet/README.md)
\
    c) explorer (IOTA Explorer for private tangle)
    - Run Ubuntu as <ins>administrator</ins>
    - Navigate to <ins>your</ins> repo path with the following Linux command
    ```console
        cd /mnt/<repo_path>/one-click-tangle/explorer/
    ```
    - Trigger shell script to set up explorer while passing the necessary network parameter
    ```console
        ./tangle-explorer.sh install [<network-definition.json> or <private-tangle-install-folder>]
    ```
    Interact with explorer as described in this [README](https://github.com/iotaledger/one-click-tangle/blob/chrysalis/explorer/README.md)