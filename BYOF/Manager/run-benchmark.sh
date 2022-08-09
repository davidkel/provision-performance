#! /bin/bash

function expand_template {
    sed -e "/workers:/{
        N
        /number: \([0-9][0-9]*\)/{
            s/type: .*\n/type: $1\n/
            s/number: [0-9][0-9]*/number: $1/
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
    echo -e "\033[1;34mlaunch remote workers by following the tutorial here: https://github.com/davidkel/provision-performance\033[0m"
fi
WORKERS=$(read_input "Number of worker [10]: " "10")
file_exists "Benchmark file relative path [create-asset]: " "../../caliper-benchmarks/benchmarks/api/fabric/create-asset.yaml"
BENCHMARK_FILE=$FILENAME

DIR="$(dirname "$(realpath "$0")")"
BENCHMARK=$DIR/benchmark.yaml
echo "$(expand_template $WORKERS)" > $BENCHMARK

if [ $REMOTE -ne "y" ]; then
    ./launch-manager.sh -b $BENCHMARK -l
else
    ./launch-manager.sh -b $BENCHMARK
fi

#TODO:
# specify a rate controller and it's parameters update the benchmark file dynamically, or at least support changing it tps and load for both fixed-tps, fixed-load
# maybe we use template benchmarks that just fill in values as specified
# launch remote workers
