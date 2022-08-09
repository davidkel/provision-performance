#! /bin/bash

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  launch-manager.sh"
  echo "     -b <path to benchmark file> - path to benchmark file"
  echo "     -i <ipaddr> - Optional ip address of mqtt broker"
  echo "     -l - Optional to run with local workers rather than utilise remote workers"
  echo "  NOTE: relative paths are relative to ~/caliper-benchmarks"
}

# parse flags

if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0;
fi

MQTT_ADDR="localhost:1883"

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -b )
    BENCHMARK_FILE="$2"
    shift
    ;;
  -i )
    MQTT_ADDR="$2"
    shift
    ;;
  -l )
    LOCALWORKER=true
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
pushd ~/caliper-benchmarks

if [ -z $BACKGROUND ]; then
  set -x
  npx caliper launch manager --caliper-workspace ./ --caliper-networkconfig $DIR/../Worker/sut-network.yaml --caliper-benchconfig $BENCHMARK_FILE --caliper-flow-only-test
else
  set -x
  npx caliper launch manager --caliper-workspace ./ --caliper-networkconfig $DIR/dummy-network.yaml --caliper-benchconfig $BENCHMARK_FILE --caliper-flow-only-test --caliper-worker-remote true --caliper-worker-communication-method mqtt --caliper-worker-communication-address mqtt://$MQTT_ADDR
fi
popd