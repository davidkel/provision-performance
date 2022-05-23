#! /bin/bash

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  manager-services <mode>"
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
   # run mosquitto
   docker run -d --rm --name mqtt -p 1883:1883 -p 9001:9001 -v $PWD/mosquitto:/mosquitto/config eclipse-mosquitto:latest

   # bring up prometheus and grafana
   cd prometheus-grafana
   docker compose up -d
   cd ..
elif [ "$MODE" == "stop" ]; then
   docker kill mqtt
   cd prometheus-grafana
   docker compose down
   cd ..
else
  printHelp
  exit 1
fi
