#!/bin/bash

##
# Copyright IBM Corporation 2020
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

### Functions
function log {
    echo "[$(date +"%m-%d-%Y %r")]: $*"
}


# get config file and properties
CONFIG_FILE=$1
log "CONFIG_FILE is: $CONFIG_FILE"




CHANNEL_NAME=`jq -r .CHANNEL_NAME "$CONFIG_FILE"`
log "CHANNEL_NAME is: $CHANNEL_NAME"

ORDERER_CONTAINER=`jq -r .ORDERER_CONTAINER "$CONFIG_FILE"`
log "ORDERER_CONTAINER is: $ORDERER_CONTAINER"

ADMIN_TLSCA_CERT=`jq -r .ADMIN_TLSCA_CERT "$CONFIG_FILE"`
log "ADMIN_TLSCA_CERT is: $ADMIN_TLSCA_CERT"

FABRIC_PATH=`jq -r .FABRIC_PATH "$CONFIG_FILE"`
log "FABRIC_PATH is: $FABRIC_PATH"

FABRIC_PATH_SIGN=`jq -r .FABRIC_PATH_SIGN "$CONFIG_FILE"`
log "FABRIC_PATH_SIGN is: $FABRIC_PATH_SIGN"


export FABRIC_CFG_PATH=$FABRIC_PATH


##### Create and marshal a Fabric ConfigUpdate proposal with configtxlator using the old and new block.
configtxlator proto_encode --input 03config_blockTrim.json --type common.Config --output 03config_blockTrim.pb
configtxlator proto_encode --input 03config_blockTrimUPDATED.json --type common.Config --output 03config_blockTrimUPDATED.pb
configtxlator compute_update --channel_id $CHANNEL_NAME --original 03config_blockTrim.pb --updated 03config_blockTrimUPDATED.pb --output 04config_blockDelta.pb

configtxlator proto_decode --input 04config_blockDelta.pb --type common.ConfigUpdate --output 04config_blockDelta.json

# add the envelope back
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat 04config_blockDelta.json)'}}}' | jq . > 05config_blockDeltaWithEnvelope.json

# create final protobuf
configtxlator proto_encode --input 05config_blockDeltaWithEnvelope.json --type common.Envelope --output 05config_blockDeltaWithEnvelope.pb

# sign the transaction protobuf  https://hyperledger-fabric.readthedocs.io/en/release-1.1/commands/peerchannel.html#peer-channel-signconfigtx
# Create a set of signatures that will satisfy the orderer system channel's update policy.
# sign Tx as PivtMSP-Admin per FABRIC_CFG_PATH
# signature is done "on-file" therefore we make a copy before the command update it
cp 05config_blockDeltaWithEnvelope.pb  06config_blockDeltaWithEnvelopeSigned.pb

export FABRIC_CFG_PATH=$FABRIC_PATH_SIGN
log "Signing channel update as: $FABRIC_CFG_PATH"
peer channel signconfigtx -f 06config_blockDeltaWithEnvelopeSigned.pb


# FINALLY Submit channel update 
export FABRIC_CFG_PATH=$FABRIC_PATH
log "Submit channel update as: $FABRIC_CFG_PATH"

peer channel update -f 06config_blockDeltaWithEnvelopeSigned.pb  -o $ORDERER_CONTAINER -c $CHANNEL_NAME --tls --cafile $ADMIN_TLSCA_CERT


#  The following steps are needed to bootstrap the new orderer node in IBP with the updated config block. 
#  Not used for other changes such as application channel updates.

# pull latest config block, now with the new updates added  
peer channel fetch config 07config_blockWithIBP.pb -o $ORDERER_CONTAINER -c $CHANNEL_NAME --tls --cafile $ADMIN_TLSCA_CERT

# We get the new block for IBP in json for visual validation as needed
configtxlator proto_decode --input 07config_blockWithIBP.pb --type common.Block  --output 07config_blockWithIBP.json

# Base64 encode the block and add JSON format
export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
cat 07config_blockWithIBP.pb | base64 $FLAG > 08config_blockWithIBPBase64.json
echo '{"b64_block":"'$(cat 08config_blockWithIBPBase64.json)'"}' | jq . > 09config_blockWithIBPBase64Final.json
