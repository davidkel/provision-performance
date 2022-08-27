# Automated performance platform deployment of native Fabric

This is a set of ansible scripts that deploy a fabric network natively to a set of VMs/Bare Metal Servers. Currently it is expected that all peers and orderers run on separate VMs, you cannot have more than 1 fabric node (peer/orderer) running in the same VM.

It supports deployment to 2 separate enviroments

1. Local docker containers simulating VM/Bare Metal Servers
2. VMs/Bare Metal Servers

The docker environment exists primarily to test the ansible script implementation however there are differences between the 2 environments which means that you cannot use the ansible scripts to start/stop the prometheus/grafana/mosquitto services. Further details will be provided later on this.

## The different types of nodes within the system

In the inventory file you define the machines that will form part of the fabric network grouped under the collections `peers` & `orderers`.
Under each group you define the different organisations and the property name you supply represents the msp id.

There is another group of machines called clients. clients are generally used to provide load generation and you may need more than 1 client to perform that load generation. `client0` is a special client and does more than be involved in the load generation. It is used to perform part of the deployment of fabric, for example generating the crypto material and running some of the peer commands (eg peer chaincode instantiate). It is also host to the prometheus and grafana servers for observability as well as the mosquitto broker required by caliper to use remote workers.

client0 should be used for load generation orchestration (eg running caliper manager) and if there is any spare resource could also be used to generate load (eg running caliper workers) but the main load generation should come from other clients.

## Deploying to Native VMs/Bare Metal Servers

**IMPORTANT: This system relies on being able to login as root currently. Some environments (eg multipass vms) won't work out of the box because they disable direct logging in as root.**

### how to enable multipass VMs
You need to enable ssh login using root as follows:

create your vms, then shell into each and `sudo nano /etc/ssh/sshd_config`
uncomment `PermitRootLogin` and set it to `PermitRootLogin yes`
change `PasswordAuthentication` to `PasswordAuthentication yes`
save the file
`sudo systemctl restart sshd`
`sudo passwd root` to set a password for root

### setup

- In the ansible directory, edit `ansible.cfg` and ensure that the default inventory file is set to the vm directory

```yaml
#inventory = ./inventory/docker/hosts.yaml
inventory = ./inventory/vm/hosts.yaml
```

or if you prefer you can run playbooks with the -i option to explicitly provide the hosts file to use

- Create your `hosts.yaml` file in the `ansible/inventory/vm/hosts.yaml` file. There is a `hosts-template.yaml` which provides guidance on creating this.
-. Either install ansible or you could build and use the `ansible/provision-vms/docker/Dockerfile.controller` to create an ansible environment

```bash
docker build -f ansible/provision-vms/docker/Dockerfile.controller -t controller:latest .
docker run -it --name controller --rm -v $PWD/ansible:/ansible controller:latest /bin/bash
```

- change to the ansible directory
- run `ssh-keygen -t rsa -b 2048` to generate a local ssh key pair if you haven't done this already (or you are using the controller docker container)
- run `apt install -y sshpass`
- run `ANSIBLE_HOST_KEY_CHECKING=False ./site-vm.yaml -e plays="all"` to perform an initial deploy and run

- Optionally bring up the monitoring and observing processes (see next sections)
- Optionally run a caliper performance benchmark
- You can login to the grafana on the machine you designated as client0

### starting/stopping the node/process monitors

```bash
ansible-playbook -e plays="monitstart" playbooks/80-start-stop-observing.yaml
```

```bash
ansible-playbook -e plays="monitstop" playbooks/80-start-stop-observing.yaml
```

### starting/stopping the prometheus/grafana servers

```bash
ansible-playbook -e plays="serverstart" playbooks/80-start-stop-observing.yaml
```

```bash
ansible-playbook -e plays="serverstop" playbooks/80-start-stop-observing.yaml
```

### starting/stopping caliper mqtt broker

```bash
ansible-playbook -e plays="mqttstart" playbooks/90-run-caliper-benchmark.yaml
```

```bash
ansible-playbook -e plays="mqttstop" playbooks/90-run-caliper-benchmark.yaml
```

#### accessing grafana

grafana is available on the client0 machine port 3000 (userid: admin, password: admin)
prometheus is available on the client0 machine port 9090

### manually running a caliper benchmark in Bare Metal Environment

- ssh into your client0 machine
- cd Manager
- nano ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml (workers: 2, tps: 200)
- ./launch-manager.sh -b ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml -l
- nano ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml (workers: 2, tps 100)
- ./launch-manager.sh -b ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml -l

Also you could use remote workers (ensure you have started the servers as it starts mosquitto needed for remote workers)

- ssh into another client0 shell
- cd ~/Worker
- ./launch-workers.sh -w 2 -i client0:1883

In the original client0 shell

- ./launch-manager.sh -b ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml -i client0:1883

## Deploying to Local Docker Containers

- In the ansible directory, edit `ansible.cfg` and ensure that the default inventory file is set to the vm directory

```yaml
inventory = ./inventory/docker/hosts.yaml
#inventory = ./inventory/vm/hosts.yaml
```

- cd Automated/provision-vms/docker
- build the controller docker image: docker build -f Dockerfile.controller -t controller:latest
- docker-compose up -d
- docker exec -it controller /bin/bash
- cd /ansible
- ./site.yaml -e "plays=all"
- optionally start the monitors and observing services

### starting/stopping the node/process monitors for docker

```bash
ansible-playbook -e plays="monitstart" playbooks/80-start-stop-observing.yaml
```

```bash
ansible-playbook -e plays="monitstop" playbooks/80-start-stop-observing.yaml
```

### starting/stopping the prometheus/grafana/mosquitto servers for docker

You can't use the ansible scripts here
In the host (ie your machine) enviroment:

- cd Automated/ansible/playbooks/static-files

#### mqtt

- docker run --rm -d --name mqtt -p 1883:1883 -p 9001:9001 --network docker_default -v $PWD/mosquitto:/mosquitto/config eclipse-mosquitto:latest

#### Prometheus

- copy /root/prometheus.yml file from client0 docker container over to this Automated/ansible/playbooks/static-files
- docker run --rm -d --name prom -v $PWD/prometheus.yml:/etc/prometheus/prometheus.yml --network docker_default -p 9090:9090 prom/prometheus:v2.32.1

#### Grafana

- docker run --rm -d --name graf -v $PWD/grafana/provisioning:/etc/grafana/provisioning -e "GF_SECURITY_ADMIN_PASSWORD=admin" -e "GF_USERS_ALLOW_SIGN_UP=false" --network docker_default -p 3000:3000 grafana/grafana:8.3.4
- change the datasource from localhost to prom in the grafana UI on localhost:3000

### manually running a caliper benchmark in docker env

- docker exec -it client0 /bin/bash
- apt install -y nano
- cd ~/Manager
- nano ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml (workers: 2, tps: 200)
- ./launch-manager.sh -b ~/caliper-benchmarks/benchmarks/api/fabric/no-op.yaml -l
- nano ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml (workers: 2, tps 100)
- ./launch-manager.sh -b ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml -l

Also you can use remote workers (which we will simulate on client0, but could be run on any client instance)

- docker exec -it client0 /bin/bash
- cd ~/Worker
- ./launch-workers.sh -w 2 -i mqtt:1883

on the original client0 shell

- ./launch-manager.sh -b ~/caliper-benchmarks/benchmarks/api/fabric/create-asset-100.yaml -i mqtt:1883
