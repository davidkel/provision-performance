#! /bin/bash

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  launch-manager.sh <path to benchmark file> <-l>"
  echo "     -l - Optional to run with local workers rather than utilise remote workers"
  echo "  NOTE: relative paths are relative to ~/caliper-benchmarks"
}

if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0;
fi

if [[ $# -ge 2 ]] & [[ "$2" -ne "-l" ]]; then
  printHelp
  exit 0;
fi

DIR="$(dirname "$(realpath "$0")")"
pushd ~/caliper-benchmarks

if [[ "$2" == "-l" ]]; then
  set -x
  npx caliper launch manager --caliper-workspace ./ --caliper-networkconfig $DIR/../Worker/sut-network.yaml --caliper-benchconfig $1 --caliper-flow-only-test
else
  set -x
  npx caliper launch manager --caliper-workspace ./ --caliper-networkconfig $DIR/dummy-network.yaml --caliper-benchconfig $1 --caliper-flow-only-test --caliper-worker-remote true --caliper-worker-communication-method mqtt --caliper-worker-communication-address mqtt://localhost:1883
fi
popd