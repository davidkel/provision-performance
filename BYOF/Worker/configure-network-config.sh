#! /bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
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

echo "Press enter if you want to use default value [default]"
CHANNEL=$(read_input "Channel [mychannel]: " "mychannel")
CCID=$(read_input "Chaincode name [fixed-asset]: " "fixed-asset")
ORGMSP=$(read_input "Org MSP [Org1MSP]: " "Org1MSP")
PEEREP=$(read_input "Peer Gateway endpoint (eg 192.168.0.60:7051): ")
PEEROVERRIDE=$(read_input "Peer SSL Override (leave blank to omit): " "#ssl-target-name-override-not-set")
file_exists "File of USER Cert: "
USERPEM=$FILENAME
file_exists "File of USER Key: "
USERKEY=$FILENAME
file_exists "File of TLS CA Cert: "
CAPEM=$FILENAME

if [ $PEEROVERRIDE != "#ssl-target-name-override-not-set" ]; then
    PEEROVERRIDE="ssl-target-name-override: $PEEROVERRIDE"
fi

DIR="$(dirname "$(realpath "$0")")"
echo "$(expand_template $CHANNEL $CCID $ORGMSP $USERPEM $USERKEY $PEEREP "$PEEROVERRIDE" $CAPEM)" > $DIR/sut-network.yaml
 
echo "Network Config file sut-network.yaml created"
