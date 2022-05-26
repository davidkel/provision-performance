#! /bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function read_input {
    local INPUT
    while [[ -z $INPUT ]]
    do
      read -p "$1" INPUT
    done
    echo $INPUT
}

function file_exists {
    local FILE

    while [[ ! -r $FILE ]]
    do
        FILE=$(read_input "$1")
        if [ ! -r $FILE ]; then
          echo $FILE does not exist or is not readable
        fi
    done
    FILENAME=$FILE
}

function expand_template {
    local UP=$(one_line_pem $4)
    local UK=$(one_line_pem $5)
    local CP=$(one_line_pem $8)
    sed -e "s/\${Channel}/$1/" \
        -e "s/\${ChaincodeID}/$2/" \
        -e "s/\${OrgMSP}/$3/" \
        -e "s#\${UserPem}#$UP#" \
        -e "s#\${UserKey}#$UK#" \
        -e "s/\${PeerEndpoint}/$6/" \
        -e "s/\${PeerOverride}/$7/" \
        -e "s#\${PeerCACert}#$CP#" \
        sut-network-template.yaml | sed -e $'s/\\\\n/\\\n            /g'
}

# TODO: Add defaults: mychannel, fixed-asset, Org1MSP
# TODO: Blank should be allowed for PEEROVERRIDE and thus delete the entry in the file
# TODO: Bash completion of files would be handy as well
CHANNEL=$(read_input "Channel: ")
CCID=$(read_input "Chaincode name: ")
ORGMSP=$(read_input "Org MSP: ")
PEEREP=$(read_input "Peer Gateway endpoint (eg 192.168.0.60:7051): ")
PEEROVERRIDE=$(read_input "Peer SSL Override: ")
file_exists "File of USER Cert: "
USERPEM=$FILENAME
file_exists "File of USER Key: "
USERKEY=$FILENAME
file_exists "File of TLS CA Cert: "
CAPEM=$FILENAME

DIR="$(dirname "$(realpath "$0")")"
echo "$(expand_template $CHANNEL $CCID $ORGMSP $USERPEM $USERKEY $PEEREP $PEEROVERRIDE $CAPEM)" > $DIR/sut-network.yaml

echo "Network Config file sut-network.yaml created"
