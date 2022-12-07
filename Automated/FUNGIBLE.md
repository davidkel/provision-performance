# Running the fungible application

This covers running the fungible application in a set of docker containers which simulate VMs. The reference of `<PROVISION-PERFORMANCE>` will refer to the root directory of this github repo

## build the controller and prepmac images

The controller image is used to provide contained access to ansible and the prepmac image is used to preinstall some dependencies which the ansible scripts will then detect as already present rather than getting each container to install the pre-requisites, so the system will perform better. The docker-compose file to be used will reference these images.

cd <PROVISION-PERFORMANCE>/Automated/provision-vms/docker

docker build -f Dockerfile.controller -t controller:latest .
docker build -f Dockerfile.prepmac -t prepmac:latest .

## Bring up the docker containers

docker-compose -f docker-compose-fungible.yaml up -d

```
running docker compose with -f docker-compose-fungible.yaml up -d
[+] Running 12/12
 ⠿ Network docker_default  Created                                                                                                                 0.1s
 ⠿ Container orderer0      Started                                                                                                                 1.8s
 ⠿ Container alice0        Started                                                                                                                 1.2s
 ⠿ Container bob0          Started                                                                                                                 2.8s
 ⠿ Container peer0         Started                                                                                                                 1.8s
 ⠿ Container client1       Started                                                                                                                 1.2s
 ⠿ Container controller    Started                                                                                                                 1.5s
 ⠿ Container charlie0      Started                                                                                                                 2.0s
 ⠿ Container issuer0       Started                                                                                                                 2.7s
 ⠿ Container peer1         Started                                                                                                                 2.4s
 ⠿ Container auditor0      Started                                                                                                                 2.3s
 ⠿ Container client0       Started                                                                                                                 1.5s
 ```

 ## Run the ansible playbooks for fungible

 This will build fabric from main and prepare everything for the fungible application but will not start the fsc nodes. Note also that `ansible.cfg` is currently configured to use `inventory = ./inventory/docker/hosts-token-fungible.yaml` which is a hosts file that specifically defines the topology of the docker containers that will host the application as well as the fabric/fsc topology in general.

 The site.yaml file does not call either 5-docker-prereqs.yaml or 5-vm-prereqs.yaml as it assumes currently a docker environment with prepmac image being used. site.yaml also doesn't provision the prometheus/grafana environment. This requires manual handling when using docker containers as VMs because it uses the docker images of prometheus and grafana which then has volume mount issues for this environment. See the README.md for more details

 docker exec -it controller /bin/bash
 cd /ansible
./site.yaml -e plays="fungible"

Do not worry about these messages
```
TASK [Query chaincode] *********************************************************************************************************************************
FAILED - RETRYING: Query chaincode (5 retries left).
FAILED - RETRYING: Query chaincode (5 retries left).
FAILED - RETRYING: Query chaincode (4 retries left).
FAILED - RETRYING: Query chaincode (4 retries left).
FAILED - RETRYING: Query chaincode (3 retries left).
FAILED - RETRYING: Query chaincode (3 retries left).
FAILED - RETRYING: Query chaincode (2 retries left).
FAILED - RETRYING: Query chaincode (2 retries left).
FAILED - RETRYING: Query chaincode (1 retries left).
FAILED - RETRYING: Query chaincode (1 retries left).
failed: [peer0] (item=ch1) => {"ansible_loop_var": "item", "attempts": 5, "changed": true, "cmd": "./peer chaincode query -C ch1 -c '{\"Args\": [\"invoke\"]}' -n tcc > /root/query.txt 2>&1", "delta": "0:00:00.071705", "end": "2022-12-07 13:52:42.449615", "item": "ch1", "msg": "non-zero return code", "rc": 1, "start": "2022-12-07 13:52:42.377910", "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}
failed: [peer1] (item=ch1) => {"ansible_loop_var": "item", "attempts": 5, "changed": true, "cmd": "./peer chaincode query -C ch1 -c '{\"Args\": [\"invoke\"]}' -n tcc > /root/query.txt 2>&1", "delta": "0:00:00.067179", "end": "2022-12-07 13:52:42.746516", "item": "ch1", "msg": "non-zero return code", "rc": 1, "start": "2022-12-07 13:52:42.679337", "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}

PLAY RECAP *********************************************************************************************************************************************
alice0                     : ok=26   changed=13   unreachable=0    failed=0    skipped=12   rescued=0    ignored=0
auditor0                   : ok=26   changed=13   unreachable=0    failed=0    skipped=12   rescued=0    ignored=0
bob0                       : ok=26   changed=13   unreachable=0    failed=0    skipped=12   rescued=0    ignored=0
charlie0                   : ok=26   changed=13   unreachable=0    failed=0    skipped=12   rescued=0    ignored=0
client0                    : ok=104  changed=50   unreachable=0    failed=0    skipped=25   rescued=0    ignored=0
client1                    : ok=35   changed=14   unreachable=0    failed=0    skipped=17   rescued=0    ignored=0
issuer0                    : ok=26   changed=13   unreachable=0    failed=0    skipped=12   rescued=0    ignored=0
orderer0                   : ok=35   changed=14   unreachable=0    failed=0    skipped=18   rescued=0    ignored=0
peer0                      : ok=47   changed=18   unreachable=0    failed=1    skipped=21   rescued=0    ignored=0
peer1                      : ok=47   changed=18   unreachable=0    failed=1    skipped=21   rescued=0    ignored=0
```

These are expected as the query transaction to check the chaincode is responding actually gets a 500 error from the chaincode as expected.

## manually run each of the FSC nodes

I use a terminal for each so I can see any error messages
for each of the nodes issuer0 (is the bootstrap node so must be started first), auditor0, alice0, bob0, charlie0 (and referenced by <node> and <node-role> will be the node without the ending 0)

```bash
docker exec -it <node> /bin/bash
export FSCNODE_CFG_PATH=/root
cd /root/fsc/fungible/cmd/<node-role>/
./<node-role> node start
```

so for example to get the issuer up and running
```bash
docker exec -it issuer0 /bin/bash
export FSCNODE_CFG_PATH=/root
cd /root/fsc/fungible/cmd/issuer/
./issuer node start
```



## register the auditor


## To run a client request
docker exec -it client1 /bin/bash

### Register the auditor

```bash
cd /root/fsc/fungible/cmd/registerauditor
./registerauditor


[110 117 108 108]
null
```

### make a client request

```bash
cd /root/fsc/fungible/cmd/fungible
./fungible view -c cc-issuer.yaml -f issue -i "{\"TokenType\":\"TOK\", \"Quantity\":10, \"Recipient\":\"alice\"}"
...
"e8be7aeb86dd7e3dc66c45ed44034fd822186a13466ab263161985e6acafd18a"
```

```bash
./fungible view -c cc-alice.yaml -f unspent -i "{\"TokenType\":\"TOK\"}"

{"tokens":[{"Id":{"tx_id":"e8be7aeb86dd7e3dc66c45ed44034fd822186a13466ab263161985e6acafd18a"},"Owner":{"raw":"MIIEcRMCc2kEggRpCgpPd25lck1TUElEEtoICiAdtOE1CCOY07ZutGpSax28Xy5SsQf4OzulUp86hM6bKhIgD31nyaSQkuL8+nbtMgTU0XdzDR0G1iJXKtSmSyMTVKIaNQoKT3duZXJNU1BJRBIFYWxpY2UaICbTf9lT201VJx/3OwR4jaNwIixrbowZUqgdZQwxlotbIgwKCk93bmVyTVNQSUQqzgcKRAogEFY36FUbdappC1QyfoL934FrD21rUe7N0pnvcyM4CyUSIDBLvCQmvMhoue5/38qUeNoTSrVhtwhX9vKcZq6sP4t9EkQKIBRJEzivigI2tWRVYjDuE7cz/cVBthBCnswyBnx44OKGEiAPB+wqiSRjWVBJbBepLGfn3YqrlFOKulcpfxLeJ3ztNxpECiAXhUh/dhmlmVms9XAHl8wdr7304qzgZ+UqY7etrhOu1xIgHV+gVm12F6qkhiFICkzPjxsEXfeqsjJrE7gpnAWd76siICN+6rkDgFjptEqm0R5kresXX/gOfz/VwjlMkxR+lCxEKiAKwDwth2DUMYQgWQJWiWDj8lgPrFdVyJVaAPK1iLJtxzIgLt+7oWZUAdDFt4EJ80YcLwrfx5AvvF8CVDetTxkfVy86IChy9KOAuv0xqTn7QTDAFQYRoT1Afx8aS8yguYxPfXVQQiAfjGTvRjoCW6+CkfhCPPqMlMNj/CTfZlYdXYq+WwxajkogAiClkEkTyOfEjGPbxikQ70IXbSA7Tf69wx4gc/l69pNSIAiATaZqX4BfFYu+pRANOaN5O81X6M5IO5ySohpm7TNYUiAOeFyV6KYSS5p9bShLbRoaoSmyRDEzc7E+5x9oe7N26logAGxRXOBpoGo5nX6psTUTkTfnOko/W0+WxT6rkl4K0WhiRAogHbThNQgjmNO2brRqUmsdvF8uUrEH+Ds7pVKfOoTOmyoSIA99Z8mkkJLi/Pp27TIE1NF3cw0dBtYiVyrUpksjE1SiaiAPGc9f1IB3EnJDpcu7U7M8SdQ1FDq65tJ/J4XHHBYMq3KIAQogGY6Tk5INSDpyYL+3MftdJfGqSTM1qecSl+SFt67zEsISIBgA3u8SHx52QmoAZl5cRHlnQyLU917a3UbevVzZkvbtGiAJBonQWF/wdeyema1pDDOVvEsxM3CzjvNVrNrc0SKXWyIgEshepduMbetKq3GAjctAj+PR52kMQ9N7TObMAWb6fap6ZzBlAjB1Qy3a1VgI3ckiVv/L8rha+KTUsXZARqQHjPrGMZw+oj4ma3MLBntvgC5X28jydEICMQD+7afSThS4RbDosjJEAueOHoK+ytJ9H9QJNiZaJxGlu5edTNSWQ5cm7jixnGGnx0GKAQCSAWgKRAogGMFdELlL7FoMfT6t9tCP3HvQv+YKryeJpJos5pDs79gSIBHQwo9Vo8vnkIdhzAns6rPDFmBIUxfIUg8n8OpwDYwHEiAuCb5xRsJCFSo0rBsb0UAvZc/cUfTz4ZFzh4TF7MMfOg=="},"Type":"TOK","Quantity":"0xa"}]}
```

Note the rather painful value for "Quantity" of "0xa"