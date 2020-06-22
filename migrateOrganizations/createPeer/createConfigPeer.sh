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




ORG_DISPLAY_NAME=`jq -r .ORG_DISPLAY_NAME "$CONFIG_FILE"`
log "ORG_DISPLAY_NAME is: $ORG_DISPLAY_NAME"

ORG_NAME=`jq -r .ORG_NAME "$CONFIG_FILE"`
log "ORG_NAME is: $ORG_NAME"

MSP_ID=`jq -r .MSP_ID "$CONFIG_FILE"`
log "MSP_ID is: $MSP_ID"

IBP_CONSOLE_URL=`jq -r .IBP_CONSOLE_URL "$CONFIG_FILE"`
log "IBP_CONSOLE_URL is: $IBP_CONSOLE_URL"

PEER_STATE_DB=`jq -r .PEER_STATE_DB "$CONFIG_FILE"`
log "PEER_STATE_DB is: $PEER_STATE_DB"

PEER_DISPLAY_NAME=`jq -r .PEER_DISPLAY_NAME "$CONFIG_FILE"`
log "PEER_DISPLAY_NAME is: $PEER_DISPLAY_NAME"




PEER_NODE_PK=`jq -r .PEER_NODE_PK "$CONFIG_FILE"`
#log "PEER_NODE_PK is: $PEER_NODE_PK"

PEER_NODE_SIGNCERT=`jq -r .PEER_NODE_SIGNCERT "$CONFIG_FILE"`
#log "PEER_NODE_SIGNCERT is: $PEER_NODE_SIGNCERT"

PEER_MSP_ROOT_CA_CERT=`jq -r .PEER_MSP_ROOT_CA_CERT "$CONFIG_FILE"`
#log "PEER_MSP_ROOT_CA_CERT is: $PEER_MSP_ROOT_CA_CERT"




PEER_MSP_ADMIN_PK=`jq -r .PEER_MSP_ADMIN_PK "$CONFIG_FILE"`
#log "PEER_MSP_ADMIN_PK is: $PEER_MSP_ADMIN_PK"

PEER_MSP_ADMIN_CERT=`jq -r .PEER_MSP_ADMIN_CERT "$CONFIG_FILE"`
#log "PEER_MSP_ADMIN_CERT is: $PEER_MSP_ADMIN_CERT"




PEER_NODE_TLS_PK=`jq -r .PEER_NODE_TLS_PK "$CONFIG_FILE"`
#log "PEER_NODE_TLS_PK is: $PEER_NODE_TLS_PK"

PEER_NODE_TLS_SIGNCERT=`jq -r .PEER_NODE_TLS_SIGNCERT "$CONFIG_FILE"`
#log "PEER_NODE_TLS_SIGNCERT is: $PEER_NODE_TLS_SIGNCERT"

PEER_MSP_ROOT_TLSCA_CERT=`jq -r .PEER_MSP_ROOT_TLSCA_CERT "$CONFIG_FILE"`
#log "PEER_MSP_ROOT_TLSCA_CERT is: $PEER_MSP_ROOT_TLSCA_CERT"




log "################ Create Peer MSP config file for IBP ################" 
(
cat<<EOF
{
    "display_name": "$ORG_DISPLAY_NAME",
    "msp_id": "$MSP_ID",
    "type": "msp",
    "admins": [
        "$PEER_MSP_ADMIN_CERT"
    ],
    "root_certs": [
        "$PEER_MSP_ROOT_CA_CERT"
    ],
    "intermediate_certs": [],
    "tls_root_certs": [
        "$PEER_MSP_ROOT_TLSCA_CERT"
    ],
    "host_url": "$IBP_CONSOLE_URL",
    "name": "$ORG_NAME"
}
EOF
)> ./IBPconfig/configPeerOrgMSP.json




log "################ Create Peer Node config file for IBP ################" 
(
cat<<EOF
{
    "display_name": "$PEER_DISPLAY_NAME",
    "state_db": "$PEER_STATE_DB",
    "msp_id": "$MSP_ID",
    "config": 
        {
            "msp": {
                "component": {
                    "keystore": "$PEER_NODE_PK",
                    "signcerts": "$PEER_NODE_SIGNCERT",
                    "cacerts": ["$PEER_MSP_ROOT_CA_CERT"],
                    "intermediatecerts": [],
                    "admincerts": ["$PEER_MSP_ADMIN_CERT"]
                },
                "tls": {
                    "keystore": "$PEER_NODE_TLS_PK",
                    "signcerts": "$PEER_NODE_TLS_SIGNCERT",
                    "cacerts": ["$PEER_MSP_ROOT_TLSCA_CERT"],
                    "intermediatecerts": [],
                    "admincerts": ["$PEER_MSP_ADMIN_CERT"]
                }
            }
        }
}
EOF
)> ./IBPconfig/configCreatePeerNode.json



log "################ Create Orderer Org Admin identity config file for IBP Console wallet (can't be API added) ################" 
(
cat<<EOF
{
    "name": "PeerOrgMspAdmin",
    "type": "identity",
    "private_key": "$PEER_MSP_ADMIN_PK",
    "cert": "$PEER_MSP_ADMIN_CERT"
}
EOF
)> ./IBPconfig/configPeerOrgAdminIBPwallet.json


