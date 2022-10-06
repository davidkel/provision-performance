multipass launch -c 1 -d 10G -m 2G -n peer0
multipass launch -c 2 -d 5G -m 1G -n manager
multipass launch -c 2 -d 5G -m 1G -n worker
