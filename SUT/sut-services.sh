#!/bin/bash
# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  sut-services <mode>"
  echo "    <mode> - one of 'start' or 'stop'"
  echo "      - 'start' - start the services"
  echo "      - 'stop' - stop the services"
}

if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

if [ "$MODE" == "start" ]; then
  # bring up prometheus exporters
  cd prometheus
  docker compose up -d
  cd ..
elif [ "$MODE" == "stop" ]; then
  cd prometheus
  docker compose down
  cd ..
fi