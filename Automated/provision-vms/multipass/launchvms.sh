# TBD
# need to include an orderer, peer1
# need to generate a hosts file based on ip addresses ?
multipass launch -c 1 -d 10G -m 2G -n peer0
multipass launch -c 2 -d 5G -m 1G -n client0 #
multipass launch -c 2 -d 5G -m 1G -n client1 # for worker


# inside vm
# curl -fsSL https://get.docker.com -o get-docker.sh
# chmod +x get-docker.sh
# ./get-docker.sh
# sudo usermod -aG docker $USER

#install docker compose ?
