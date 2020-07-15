#!/bin/bash


#!/bin/bash

# Environment for OrdererMSP

export CORE_PEER_MSPCONFIGPATH=/Users/jorgego/Documents/CODE/fabricToIBPmigration/upgradeOrderer/crypto-config/ordererOrganizations/groeifabriek.nl/users/Admin@groeifabriek.nl/Admin@GroeifabriekMSP

export CORE_PEER_LOCALMSPID="GroeifabriekMSP"

export CORE_PEER_TLS_ROOTCERT_FILE=/Users/jorgego/Documents/CODE/fabricToIBPmigration/upgradeOrderer/crypto-config/ordererOrganizations/groeifabriek.nl/users/Admin@groeifabriek.nl/Admin@GroeifabriekMSP/tlscacerts/cert.pem

export CORE_PEER_TLS_ENABLED=true

export CHANNEL_STATE=normal

export FABRIC_CFG_PATH=$CORE_PEER_MSPCONFIGPATH

export CH_NAME=common

export ORDERER_ENDPOINT=orderer0.groeifabriek.nl
export ORDERER_PORT=7050

export TLS_ROOT_CA=$CORE_PEER_TLS_ROOTCERT_FILE

peer channel fetch config 01config_block.pb -o $ORDERER_ENDPOINT:$ORDERER_PORT -c $CH_NAME  --cafile $TLS_ROOT_CA --tls
configtxlator proto_decode --input 01config_block.pb --type common.Block --output 01config_block.json



# Invoke channel configuration updater with parameters
./fabric-config-updater \
    changeChannelState \
    -channelState=$CHANNEL_STATE \
    -signer=$CORE_PEER_MSPCONFIGPATH \
    -attachSignature=$CORE_PEER_MSPCONFIGPATH \
    -configUpdatePath=./output_envelope.pb \
    -channelID=$CH_NAME \
    -blockPath=./01config_block.pb 
echo "Completed config change state in the block."

peer channel update -f output_envelope.pb -c $CH_NAME -o $ORDERER_ENDPOINT:$ORDERER_PORT  --cafile $TLS_ROOT_CA --tls
echo "Completed config channel update - change state."

peer channel fetch config 02config_block.pb -o $ORDERER_ENDPOINT:$ORDERER_PORT -c $CH_NAME  --cafile $TLS_ROOT_CA --tls
configtxlator proto_decode --input 02config_block.pb --type common.Block --output 02config_block.json
echo "Fetched last config block."