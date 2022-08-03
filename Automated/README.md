# notes


## quick start for docker

docker is the default because`ansible.cfg` points to the docker inventory

1. cd Automated/provision-vms/docker
2. build the controller docker image: docker build -f Dockerfile.controller -t controller:latest
3. docker-compose up -d
4. docker exec -it controller /bin/bash
5. cd /ansible
6. ./site.yaml -e "playes=all"
7. docker exec -it client0 /bin/bash
8. apt install -y nano
9. cd ~/Manager
10. nano ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml (change workers and tps to 2, 300)
11. ./launch-manager.sh ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml -l
12. nano ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml (change workers and tps to 2, 100)
13. ./launch-manager.sh ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml -l

## initial issues I saw

docker I see some failures

- sometimes can't get the ssh key for some hosts (can on next run) - soln: don't need the ssh support for docker
- go install failed because it wasn't on the path                  - soln: we link go to usr/bin


fatal: [s6client0]: FAILED! => {"msg": "to use the 'ssh' connection type with passwords, you must install the sshpass program"}
export ANSIBLE_HOST_KEY_CHECKING=False ./site.yaml -e plays="all" -i inventory/test/hosts

## VM controller

- ssh-keygen -t rsa -b 2048
- apt install sshpass
- ssh into machines for the first time to add fingerprints or export ANSIBLE_HOST_KEY_CHECKING=False ./site.yaml -e plays="all" -i inventory/vm/hosts.yaml


## TODO

- Fabric
  - support v2 lifecycle (Optional)
  - support couchdb (Optional)
- prom/graf
  - need to create separate dashboards for nodes/processes, fabric metrics, fsc metrics (I have node and fabric on a single page at the moment)
  - deploy configured process exporter as alternative to nmon
- Workload
  - distinguish clients maybe (client0 runs: fabric generation, some of the fabric config, prometheus/grafana, caliper manager)
  - run an ansible driven workload (how to setup workers and benchmark file)
  - collect the results from prometheus/caliper etc
- reliability
  - support state of absent to remove things as well
  - need to add retries for some things
  - need to improve the idempotency so if a re-run is done then it will work and not affect anything
- other
  - shutdown env
  - address hardcoded paths (hopefully not too much to do)
  - TODOs in code
  - Use an external builder and remove need for docker
  - rationlise remote_user vs become but this system effectively requires user to be root all the time, Whole system relies on being able to login as root in many places, In other places they use become which is pointless as it needs root login anyway
  - look at need to gather facts everywhere, also we could set some facts on remote systems if it would be helpful

## Deploy a caliper manager to test in docker

```bash
docker run -it --rm --name manager --network docker_default ubuntu:20.04 /bin/bash

# install useful tools
cd
apt update
apt install -y git curl nano iputils-ping

# install node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 14

# install caliper benchmarks + caliper
git clone https://github.com/hyperledger/caliper-benchmarks
cd caliper-benchmarks
npm install @hyperledger/caliper-cli@0.5.0
npx caliper bind --caliper-bind-sut fabric:2.4

# install provision performance tools
cd ..
git clone https://github.com/davidkel/provision-performance
cd provision-performance/Worker

# perform these manually
./configure-network-config.sh
# create the keys
# peer0:7051
# peerOrg0MSP
# no ssl override

# run a no-op workload
cd ../Manager
nano ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml
# 4 worker, 300 tps
./launch-manager.sh ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml -l

# run a 100 byte asset workload
nano ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml
# 4 worker, 100 tps
./launch-manager.sh ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml -l
```

## starting/stopping the monitors

ansible-playbook -e plays="monitstart" playbooks/80-start-stop-observing.yaml
ansible-playbook -e plays="monitstop" playbooks/80-start-stop-observing.yaml

## starting/stopping the prometheus/grafana servers

ansible-playbook -e plays="serverstart" playbooks/80-start-stop-observing.yaml (need to start manually for docker, see next section )
ansible-playbook -e plays="serverstop" playbooks/80-start-stop-observing.yaml

### Run prometheus and grafana servers within docker env

In the host enviroment:

- cd Automated/ansible/playbooks/static-files
- copy /root/prometheus.yml file from client0 over to this dir
- docker run --rm -d --name prom -v $PWD/prometheus.yml:/etc/prometheus/prometheus.yml --network docker_default -p 9090:9090 prom/prometheus:v2.32.1
- docker run --rm -d --name graf -v $PWD/grafana/provisioning:/etc/grafana/provisioning -e "GF_SECURITY_ADMIN_PASSWORD=admin" -e "GF_USERS_ALLOW_SIGN_UP=false" --network docker_default -p 3000:3000 grafana/grafana:8.3.4
- change the datasource from localhost to prom

## stopping and restarting fabric

TBD

## manually running a caliper benchmark in docker env

- docker exec -it client0 /bin/bash
- cd Manager
- nano ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml (workers: 2, tps: 200)
- ./launch-manager.sh ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml -l
- nano ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml (workers: 2, tps 100)
- ./launch-manager.sh ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml -l
















## Issues when deploying to Fyre VMs

- failed on one to deploy docker, had to run again to complete need retries
- chaincode install appeared to work but ansible saw it as a failure and tried 3 times and the message was it failed as it was already installed (fixed by making install idempotent)
- instantiate failed Failed to pull hyperledger/fabric-ccenv:latest worked in docker because I have this image, but can't seem to address the problem by pulling and tagging on the peer (have changed def to use 2.4 images)
- restart-nodes, orderer failed to restart but started ok on next attempt


relook and rectify

mismatch on when to use peer_name vs ansible_host

^[[31m2022-07-28 07:30:17.949 PDT 00dd ERRO^[[0m [core.comm] ^[[31;1mServerHandshake^[[0m -> Server TLS handshake failed in 1.948397ms with error remote error: tls: bad certificate server=PeerServer re>^[[31m2022-07-28 07:30:18.953 PDT 00de ERRO^[[0m [core.comm] ^[[31;1mServerHandshake^[[0m -> Server TLS handshake failed in 1.910147ms with error remote error: tls: bad certificate server=PeerServer re>^[[31m2022-07-28 07:30:20.618 PDT 00df ERRO^[[0m [core.comm] ^[[31;1mServerHandshake^[[0m -> Server TLS handshake failed in 2.199035ms with error remote error: tls: bad certificate server=PeerServer re>^[[33m2022-07-28 07:30:20.945 PDT 00e0 WARN^[[0m [gossip.comm] ^[[33;1msendToEndpoint^[[0m -> Failed obtaining connection for 10.51.4.159:7051, PKIid:0d4d5b6df26189a46116411ed57f8ef3e5f3dfd0d78799a38f3>^[[34m2022-07-28 07:30:47.947 PDT 00e1 INFO^[[0m [comm.grpc.server] ^[[34;1m1^[[0m -> unary call completed grpc.service=gossip.Gossip grpc.method=Ping grpc.request_deadline=2022-07-28T07:30:49.946-07:0>^[[34m2022-07-28 07:30:47.949 PDT 00e2 INFO^[[0m [comm.grpc.server] ^[[34;1m1^[[0m -> streaming call completed grpc.service=gossip.Gossip grpc.method=GossipStream grpc.peer_address=9.20.197.235:48914 g>^[[31m2022-07-28 07:30:47.955 PDT 00e3 ERRO^[[0m [core.comm] ^[[31;1mServerHandshake^[[0m -> Server TLS handshake failed in 1.829995ms with error remote error: tls: bad certificate server=PeerServer re>^[[31m2022-07-28 07:30:48.958 PDT 00e4 ERRO^[[0m [core.comm] ^[[31;1mServerHandshake^[[0m -> Server TLS handshake failed in 1.711587ms with error remote error: tls: bad certificate server=PeerServer re>^[[31m2022-07-28 07:30:50.808 PDT 00e5 ERRO^[[0m [core.comm] ^[[31;1mServerHandshake^[[0m -> Server TLS handshake failed in 1.402519ms with error remote error: tls: bad certificate server=PeerServer re>^[[33m2022-07-28 07:30:50.952 PDT 00e6 WARN^[[0m [gossip.comm] ^[[33;1msendToEndpoint^[[0m -> Failed obtaining connection for 10.51.4.159:7051, PKIid:0d4d5b6df26189a46116411ed57f8ef3e5f3dfd0d78799a38f3>^[[34m2022-07-28 07:31:17.944 PDT 00e7 INFO^[[0m [comm.grpc.server] ^[[34;1m1^[[0m -> unary call completed grpc.service=gossip.Gossip grpc.method=Ping grpc.request_deadline=2022-07-28T07:31:19.944-07:0>^[[34m2022-07-28 07:31:17.954 PDT 00e8 INFO^[[0m [comm.grpc.server] ^[[34;1m1^[[0m -> streaming call completed grpc.service=gossip.Gossip grpc.method=GossipStream grpc.peer_address=9.20.197.235:48924 g>


root@untidily1:~# cat /proc/21008/environ
SHELL=/bin/bash
CORE_PEER_PREFERREDORDERERENDPOINT=
CORE_PEER_LOCALMSPID=peerOrg0MSP
TMUX=/tmp/tmux-0/default,20998,0
CORE_OPERATIONS_LISTENADDRESS=0.0.0.0:9443
CORE_PEER_ID=peer0
CORE_PEER_ADDRESS=0.0.0.0:7051
FABRIC_CFG_PATH=/src/github.com/hyperledger/fabric/sampleconfig/
PWD=/src/github.com/hyperledger/fabric/build/bin
LOGNAME=root
CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0:7051
XDG_SESSION_TYPE=tty
CORE_PEER_PROFILE_ENABLED=False
MOTD_SHOWN=pam
HOME=/root
CORE_CHAINCODE_LOGGING_LEVEL=info
LANG=en_US.UTF-8LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:
CORE_PEER_TLS_CERT_FILE=/root/crypto-config/peerOrganizations/peerOrg0/peers/peer0/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/root/crypto-config/peerOrganizations/peerOrg0/peers/peer0/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/root/crypto-config/peerOrganizations/peerOrg0/peers/peer0/tls/ca.crt
SSH_CONNECTION=9.171.95.131 52292 9.20.197.235 22
CORE_PEER_MSPCONFIGPATH=/root/crypto-config/peerOrganizations/peerOrg0/peers/peer0/msp
/GOROOT=/usr/local/go
LESSCLOSE=/usr/bin/lesspipe %s %s
XDG_SESSION_CLASS=user
TERM=screen
CORE_PEER_GOSSIP_BOOTSTRAP=peer0:7051
LESSOPEN=| /usr/bin/lesspipe %s
CORE_VM_DOCKER_ATTACHSTDOUT=FalseUSER=root
CORE_PEER_TLS_ENABLED=True
TMUX_PANE=%0
FABRIC_LOGGING_SPEC=INFO
SHLVL=1
XDG_SESSION_ID=51
LC_CTYPE=C.UTF-8
XDG_RUNTIME_DIR=/run/user/0
SSH_CLIENT=9.171.95.131 52292 2
2CORE_METRICS_PROVIDER=prometheus
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/local/go/bin:/root/gopath/bin:/usr/local/go/bin:/root/gopath/bin
CORE_CHAINCODE_BUILDER=hyperledger/fabric-ccenv:2.4
FOOBAR=True
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/0/bus
CORE_CHAINCODE_GOLANG_RUNTIME=hyperledger/fabric-baseos:2.4
SSH_TTY=/dev/pts/1
GOPATH=/root/gopath
_=./peer


configtx.yaml
-------------
ansible_host for ordererEndpoints
ansible_host for consenters


cryptoconfig
------------
peer_name + ansible_host

anchor peer is ansible_host