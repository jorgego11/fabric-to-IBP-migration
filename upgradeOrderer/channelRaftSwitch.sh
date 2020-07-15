#!/bin/bash
#  TODO   save  network settings,   recreate the network with persistance,   verify TLS  values for orderer pods

#!/bin/bash

# Environment for OrdererMSP

export CORE_PEER_MSPCONFIGPATH=/Users/jorgego/Documents/CODE/fabricToIBPmigration/upgradeOrderer/crypto-config/ordererOrganizations/groeifabriek.nl/users/Admin@groeifabriek.nl/Admin@GroeifabriekMSP

export CORE_PEER_LOCALMSPID="GroeifabriekMSP"

export CORE_PEER_TLS_ROOTCERT_FILE=/Users/jorgego/Documents/CODE/fabricToIBPmigration/upgradeOrderer/crypto-config/ordererOrganizations/groeifabriek.nl/users/Admin@groeifabriek.nl/Admin@GroeifabriekMSP/tlscacerts/cert.pem

export CORE_PEER_TLS_ENABLED=true

export FABRIC_CFG_PATH=$CORE_PEER_MSPCONFIGPATH

export TLS_ROOT_CA=$CORE_PEER_TLS_ROOTCERT_FILE

export CH_NAME=common

export ORDERER_ENDPOINT=orderer0.groeifabriek.nl
export ORDERER_PORT=7050

# These are the existing Kafka orderer nodes that will be converted to Raft for "in-place" ledger migration
# We will use the internal enpoint. Peers talk to these orderers on port 7050 BUT Orderer to Orderer comms happens on port 7090 over TLS
export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
export ORDERER_TLS=$(cat /Users/jorgego/Documents/CODE/fabricToIBPmigration/upgradeOrderer/crypto-config/ordererOrganizations/groeifabriek.nl/orderers/orderer0.groeifabriek.nl/tls/server.crt | base64 $FLAG)

export ORDERER_INTERNAL_ENDPOINT_0=hlf-orderer--groeifabriek--orderer0
export ORDERER_PORT_0=7050
export ORDERER_TLS_0=$ORDERER_TLS

export ORDERER_INTERNAL_ENDPOINT_1=orderer0-1-new-service
export ORDERER_PORT_1=7050
export ORDERER_TLS_1=$ORDERER_TLS

export ORDERER_INTERNAL_ENDPOINT_2=orderer0-2-new-service
export ORDERER_PORT_2=7050
export ORDERER_TLS_2=$ORDERER_TLS




peer channel fetch config 01config_block.pb -o $ORDERER_ENDPOINT:$ORDERER_PORT -c $CH_NAME  --cafile $TLS_ROOT_CA --tls
configtxlator proto_decode --input 01config_block.pb --type common.Block --output 01config_block.json
echo "Completed pulling block and translate to json."


# Invoke channel configuration updater with parameters
./fabric-config-updater \
    migrateKafkaToRaft \
    -signer=$CORE_PEER_MSPCONFIGPATH \
    -attachSignature=$CORE_PEER_MSPCONFIGPATH \
    -blockPath=./01config_block.pb \
    -configUpdatePath=./output_envelope.pb \
    -channelID=$CH_NAME \
    -ordererHost=$ORDERER_INTERNAL_ENDPOINT_0 \
    -ordererPort=$ORDERER_PORT_0 \
    -ordererTLSCert=$ORDERER_TLS_0

 ./fabric-config-updater \
    addConsenter \
    -signer=$CORE_PEER_MSPCONFIGPATH \
    -attachSignature=$CORE_PEER_MSPCONFIGPATH \
    -blockPath=./01config_block.pb \
    -configUpdatePath=./output_envelope.pb \
    -channelID=$CH_NAME \
    -ordererHost=$ORDERER_INTERNAL_ENDPOINT_1 \
    -ordererPort=$ORDERER_PORT_1 \
    -ordererTLSCert=$ORDERER_TLS_1   

 ./fabric-config-updater \
    addConsenter \
    -signer=$CORE_PEER_MSPCONFIGPATH \
    -attachSignature=$CORE_PEER_MSPCONFIGPATH \
    -blockPath=./01config_block.pb \
    -configUpdatePath=./output_envelope.pb \
    -channelID=$CH_NAME \
    -ordererHost=$ORDERER_INTERNAL_ENDPOINT_2 \
    -ordererPort=$ORDERER_PORT_2 \
    -ordererTLSCert=$ORDERER_TLS_2


echo "Completed config change state in the block."

peer channel update -f output_envelope.pb -c $CH_NAME -o $ORDERER_ENDPOINT:$ORDERER_PORT  --cafile $TLS_ROOT_CA --tls
echo "Completed config channel update - change state."

peer channel fetch config 02config_block.pb -o $ORDERER_ENDPOINT:$ORDERER_PORT -c $CH_NAME  --cafile $TLS_ROOT_CA  --tls
configtxlator proto_decode --input 02config_block.pb --type common.Block --output 02config_block.json
echo "Fetched last config block."