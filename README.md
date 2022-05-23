# provision-performance

![Architecture](PerformancePlatform.jpg)


## SUT
curl -ssL https://raw.githubusercontent.com/davidkel/provision-performance/main/SUT/install.sh > install.sh
cd provision-performance/SUT
run-services.sh

## Manager
curl -ssL https://raw.githubusercontent.com/davidkel/provision-performance/main/Manager/install.sh > install.sh


## create a network config
- need an identity
- need details of the peer
- need name of channel and id of chaincode installed

```
name: Fabric
version: "2.0.0"

caliper:
  blockchain: fabric
  sutOptions:
    mutualTls: false

channels:
  - channelName: mychannel
    contracts:
    - id: basic

organizations:
  - mspid: Org1MSP
    identities:
      certificates:
      - name: 'user.org1.example.com'
        clientPrivateKey:
          pem: |-
            -----BEGIN PRIVATE KEY-----
            ...
            -----END PRIVATE KEY-----
        clientSignedCert:
          pem: |-
            -----BEGIN CERTIFICATE-----
            ...
            -----END CERTIFICATE-----
    peers:
      - endpoint: peer0.org1.example.com:7051
        grpcOptions:
          ssl-target-name-override: peer0.org1.example.com
          grpc.keepalive_time_ms: 600000
        tlsCACerts:
          pem: |-
            -----BEGIN CERTIFICATE-----
            ...
            -----END CERTIFICATE-----
```


## Configure prometheus

need to point to the node/process/peer/orderer exporters in prometheus/prometheus.yml
ie ip address of SUT machine

```
#scrape_configs:
#  - job_name: "prometheus"
#    static_configs:
#      - targets: ["localhost:9090"]
#  - job_name: "orderer"
#    static_configs:
#      - targets: ["localhost:9443"]
#  - job_name: "peer0_org1"
#    static_configs:
#      - targets: ["localhost:9444"]
#  - job_name: "peer0_org2"
#    static_configs:
#      - targets: ["localhost:9445"]
#  - job_name: node
#    static_configs:
#      - targets: ['localhost:9100']
#  - job_name: process
#    static_configs:
#      - targets: ['localhost:9256']
```

## Benchmark files
Need to decide on workers
Need to see of these benchmark files are appropriate or we create another set and store elsewhere

## Launching a manager

npx caliper launch manager --caliper-workspace ./ --caliper-networkconfig networks/<ANY NETWORK CONFIG>.yaml --caliper-benchconfig <YOUR BENCHMARK FILE eg benchmarks/api/fabric/empty-contract-test.yaml> --caliper-flow-only-test --caliper-worker-remote true --caliper-worker-communication-method mqtt --caliper-worker-communication-address mqtt://localhost:1883

## Launching a worker
npx caliper launch worker --caliper-worker-remote true --caliper-worker-communication-method mqtt --caliper-worker-communication-address mqtt://<IP_ADDR_OF_CALIPER_MANAGER>:1883 --caliper-workspace ./ --caliper-networkconfig networks/<YOUR NETWORK CONFIG>.yaml --caliper-benchconfig <ANY BENCHMARK FILE eg benchmarks/api/fabric/empty-contract-test.yaml>

## TODO

make it as turnkey as possible

1. sut-network generation from template
2. prometheus config generation from template
3. template caliper benchmarks
4. benchmark files to extract prometheus data
5. use pushgateway to capture worker stats
6. prometheus to scrape caliper manager (requires a new caliper feature)
7. add manager and worker vms to dashboard maybe
8.
