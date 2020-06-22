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


export FABRIC_CFG_PATH=$FABRIC_PATH

#  remove previous run intermediate files
rm ??config_block*

#  Get latest config block for the "orderer system channel"
peer channel fetch config 01config_block.pb -o $ORDERER_CONTAINER -c $CHANNEL_NAME --tls --cafile $ADMIN_TLSCA_CERT

##### covert the protobuf version of the channel config into a JSON 
configtxlator proto_decode --input 01config_block.pb --type common.Block --output 02config_block.json

#### Extract just the config section in the json file and make a copy
cat 02config_block.json | jq .data.data[0].payload.data.config > 03config_blockTrim.json
cp 03config_blockTrim.json 03config_blockTrimUPDATED.json
