## Set up One-Click-Tangle Docker environment on Windows 10

##### 1. Docker Installation 
- Install [Docker for Windows](https://docs.docker.com/desktop/windows/install)
- Make sure to also install the required Windows components for WSL 2 ([Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about))

##### 2. Check Version
- After the installation you should check your **Docker** (`>=18.03`) and **Docker Compose** (`>=1.21`) versions using the following CMD commands
    ```console
    docker -v
    docker-compose -v
    ```

##### 3. Install Ubuntu
- Install Ubuntu distribution using the following CMD commands step by step (list available distributions / install Ubuntu / check version)
    ```console
    wsl --list --online
    wsl --install --distribution Ubuntu
    wsl -l -v
    ```

##### 4. Set Default Distribution
- Make Ubuntu your default WSL distribution by using the following CMD commands (set default distribution / check new default)
    ```console
    wsl --set-default Ubuntu
    wsl --list
    ```

##### 5. Docker Desktop Settings
- Enable WSL integration with new Ubuntu distribution (*Settings > Resources > WSL INTEGRATION*)
- Make sure Docker Compose v2 is <ins>deactivated</ins> (*Settings>General*)
- You can also deactivate Docker Compose v2 by running
    ```console
    docker-compose disable-v2
    ```

##### 6. Clone Repo
- Clone [one-click-tangle](https://github.com/iotaledger/one-click-tangle) repository with the following CMD commands
    ```console
    git clone https://github.com/iotaledger/one-click-tangle
    cd one-click-tangle
    ```

##### 7. Install One-Click-Tangle Components
- Now you can install different components available in the one-click-tangle repo
- **NOTE:** Instead of using the mentioned `chmod` command in the referenced readme's, you need to run Ubuntu as <ins>administrator</ins> for the necessary rights

- ##### Private Hornet Node Tangle
    - Navigate to `hornet-private-tangle` folder in the `one-click-tangle` repo
    ```console
        cd /mnt/<repo_path>/one-click-tangle/hornet-private-net/
    ```
    - Run commands as described in the hornet-private-net [readme](/hornet-private-net/README.md)
    - **NOTE:** When installing the private tangle script it's recommended to use a `coo_bootstrap_wait_time` of 30 seconds
        - `./private-tangle.sh install 30`
- ##### Mainnet Hornet Node
    - Navigate to `hornet-mainnet` folder in the `one-click-tangle` repo
    ```console
        cd /mnt/<repo_path>/one-click-tangle/hornet-mainnet/
    ```
    - Run commands as described in the hornet-mainnet [readme](/hornet-mainnet/README.md)
- ##### IOTA Explorer
    - Navigate to `explorer` folder in the `one-click-tangle` repo
    ```console
        cd /mnt/<repo_path>/one-click-tangle/explorer/
    ```
    - Run commands as described in the explorer [readme](/explorer/README.md)