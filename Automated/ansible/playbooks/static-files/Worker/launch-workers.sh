#! /bin/bash
# parameter to specify number of workers
# parameter to specify mqtt address (ie ip address of manager)

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  launch-workers.sh "
  echo "      -w <workers> - number of workers to launch"
  echo "      -i <ipaddr> - ip address of mqtt broker"
  echo "      -b - run all workers in background"
  echo ""
  echo "Example: ./launch-workers.sh -w 5 -i 192.168.0.10"
}

if [[ $# -lt 4 ]] ; then
  printHelp
  exit 0
fi

# parse flags

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -w )
    WORKERS="$2"
    shift
    ;;
  -i )
    MQTT_ADDR="$2"
    shift
    ;;
  -b )
    BACKGROUND=true
    ;;
  * )
    echo "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

if [ -z $WORKERS ] | [ -z $MQTT_ADDR ]; then
  printHelp
  exit 1
fi

DIR="$(dirname "$(realpath "$0")")"
NETWORKCONFIG=$DIR/sut-network.yaml
if [ ! -r $NETWORKCONFIG ]; then
  echo $NETWORKCONFIG does not exist or is not readable
  echo please run ./configure-network-config.sh
  exit 1
fi

DUMMYBENCHMARK=$DIR/dummy-benchmark.yaml
pushd ~/caliper-benchmarks
START=0
if [ -z $BACKGROUND ]; then
   START=1
fi

set -x
for ((i=$START; i<$WORKERS; i++))
do
  npx caliper launch worker --caliper-worker-remote true --caliper-worker-communication-method mqtt --caliper-worker-communication-address mqtt://$MQTT_ADDR:1883 --caliper-workspace ./ --caliper-networkconfig $NETWORKCONFIG --caliper-benchconfig $DUMMYBENCHMARK &
done
if [ -z $BACKGROUND ]; then
  npx caliper launch worker --caliper-worker-remote true --caliper-worker-communication-method mqtt --caliper-worker-communication-address mqtt://$MQTT_ADDR:1883 --caliper-workspace ./ --caliper-networkconfig $NETWORKCONFIG --caliper-benchconfig $DUMMYBENCHMARK
fi
popd

