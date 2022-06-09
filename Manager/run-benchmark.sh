#! /bin/bash

function expand_template {
    sed -e "/workers:/{
        N
        /type: \(.*\)/{
            N
            /number: \([0-9][0-9]*\)/{
                s/type: .*\n/type: $1\n/
                s/number: [0-9][0-9]*/number: $2/
                }
            }
        }" \
        $BENCHMARK_FILE | sed -e $'s/\\\\n/\\\n            /g'
}

function read_input {
    local INPUT
    while [[ -z $INPUT ]]
    do
        read -e -p "$1" INPUT
        if [ $# -eq 2 ]; then 
            INPUT=${INPUT:-"$2"}
        fi
    done
    echo $INPUT
}

function file_exists {
    local FILE

    while [[ ! -r $FILE ]]
    do
        FILE=$(read_input "$1" "$2")
        if [ ! -r $FILE ]; then
          echo $FILE does not exist or is not readable
        fi
    done
    FILENAME=$FILE
}

echo -e "Press enter if you want to use default value [default]"
REMOTE=$(read_input "Remote workers(y/n)[y]: " "y")
if [ $REMOTE == "y" ]; then
    REMOTE="remote"
    echo -e "\033[1;34mlaunch remote workers by following the tutorial here: https://github.com/davidkel/provision-performance\033[0m"
else
    REMOTE="local"
fi
WORKERS=$(read_input "Number of worker [10]: " "10")
CONTROLLER=$(read_input "Rate Controller to use [fixed-load]: " "fixed-load")
file_exists "Benchmark file relative path [create-asset]: " "../../caliper-benchmarks/benchmarks/api/fabric/create-asset.yaml"
BENCHMARK_FILE=$FILENAME

DIR="$(dirname "$(realpath "$0")")"
BENCHMARK=$DIR/benchmark.yaml
echo "$(expand_template $REMOTE $WORKERS $CONTROLLER)" > $BENCHMARK

if [ $REMOTE == "local" ]; then
    pushd ../Worker
    ./configure-network-config.sh
    popd
    ./launch-manager.sh $BENCHMARK -l
else
    ./launch-manager.sh $BENCHMARK
fi
#TODO:
# specify a rate controller and it's parameters update the benchmark file dynamically
# launch remote workers //can we start remote workers from the manager vm?
# launch local workers //this will happen in the ./launch-workers.sh if we pass the -l flag
# do we want to not separate remote from local and always use mosquitto and just ask for how many local and remote the user wants and connect them all to mosqitto
# add substitution of rate controller and its options as well