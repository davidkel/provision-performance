#! /bin/bash

# option to try to provision via apis

sudo apt update
sudo apt install -y git
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo groupadd docker
sudo usermod -aG docker $USER
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 14
git clone https://github.com/hyperledger/caliper-benchmarks
cd caliper-benchmarks
npm install @hyperledger/caliper-cli@0.5.0

# only required for HSM testing
# sudo apt install -y build-essential

# Include this as a manager can also be a worker
npx caliper bind --caliper-bind-sut fabric:2.4
cd ..
git clone https://github.com/davidkel/provision-performance
