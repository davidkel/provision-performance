#!/bin/bash

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  configure-prometheus.sh"
  echo "      -i - ip address of SUT"
  echo "      -p - comma separated peer ports on SUT"
  echo "      -o - comma separated orderer ports on SUT"
  echo ""
  echo "Example: ./configure-prometheus.sh -i 192.168.0.10 -p 9444.9445 -o 9443"
}

if [[ $# -lt 6 ]] ; then
  printHelp
  exit 0;
fi

# parse flags

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -p )
    PEER_PORTS="$2"
    shift
    ;;
  -o )
    ORDERER_PORTS="$2"
    shift
    ;;
  -i )
    SUT_ADDR="$2"
    shift
    ;;
  * )
    echo "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

DIR="$(dirname "$(realpath "$0")")"

cat << EOF > $DIR/prometheus-grafana/prometheus/prometheus.yml
global:
  scrape_interval: 1s
  external_labels:
    monitor: 'sut-monitor'

scrape_configs:
  - job_name: node
    static_configs:
      - targets: ['$SUT_ADDR:9100']
  - job_name: process
    static_configs:
      - targets: ['$SUT_ADDR:9256']
EOF

for PORT in $(echo $PEER_PORTS | sed "s/,/ /g")
do
   cat << EOF >> $DIR/prometheus-grafana/prometheus/prometheus.yml
  - job_name: "peer_$PORT"
    static_configs:
      - targets: ["$SUT_ADDR:$PORT"]
EOF
done

for PORT in $(echo $ORDERER_PORTS | sed "s/,/ /g")
do
   cat << EOF >> $DIR/prometheus-grafana/prometheus/prometheus.yml
  - job_name: "orderer_$PORT"
    static_configs:
      - targets: ["$SUT_ADDR:$PORT"]
EOF
done

echo $DIR/prometheus-grafana/prometheus/prometheus.yml generated
