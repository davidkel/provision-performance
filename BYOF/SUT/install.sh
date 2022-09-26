#! /bin/bash

sudo apt update
sudo apt install -y git jq
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo groupadd docker
sudo usermod -aG docker $USER
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 14
# needed for gvm
sudo apt install -y build-essential
sudo apt install -y bison
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
source /home/ubuntu/.gvm/scripts/gvm
gvm install go1.18.2 -B
gvm use go1.18.2 --default
git clone https://github.com/hyperledger/caliper-benchmarks
# cd caliper-benchmarks
# npm install @hyperledger/caliper-cli@0.5.0
# only required for HSM testing
# sudo apt update && sudo apt install build-essential
# npx caliper bind --caliper-bind-sut fabric:2.4


git clone https://github.com/davidkel/provision-performance

# curl -ssL https://raw.githubusercontent.com/davidkel/provision-performance/main/SUT/run-services.sh > run-services.sh
# chmod +x run-services.sh
