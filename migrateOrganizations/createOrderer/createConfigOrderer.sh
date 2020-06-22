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

SYSTEM_CHANNEL_ID=`jq -r .SYSTEM_CHANNEL_ID "$CONFIG_FILE"`
log "SYSTEM_CHANNEL_ID is: $SYSTEM_CHANNEL_ID"

CLUSTER_ID=`jq -r .CLUSTER_ID "$CONFIG_FILE"`
log "CLUSTER_ID is: $CLUSTER_ID"

ORDERER_CLUSTER_NAME=`jq -r .ORDERER_CLUSTER_NAME "$CONFIG_FILE"`
log "ORDERER_CLUSTER_NAME is: $ORDERER_CLUSTER_NAME"

ORDERER_DISPLAY_NAME=`jq -r .ORDERER_DISPLAY_NAME "$CONFIG_FILE"`
log "ORDERER_DISPLAY_NAME is: $ORDERER_DISPLAY_NAME"




ORDERER_NODE_PK=`jq -r .ORDERER_NODE_PK "$CONFIG_FILE"`
#log "ORDERER_NODE_PK is: $ORDERER_NODE_PK"

ORDERER_NODE_SIGNCERT=`jq -r .ORDERER_NODE_SIGNCERT "$CONFIG_FILE"`
#log "ORDERER_NODE_SIGNCERT is: $ORDERER_NODE_SIGNCERT"

ORDERER_MSP_ROOT_CA_CERT=`jq -r .ORDERER_MSP_ROOT_CA_CERT "$CONFIG_FILE"`
#log "ORDERER_MSP_ROOT_CA_CERT is: $ORDERER_MSP_ROOT_CA_CERT"



ORDERER_MSP_ADMIN_PK=`jq -r .ORDERER_MSP_ADMIN_PK "$CONFIG_FILE"`
#log "ORDERER_MSP_ADMIN_PK is: $ORDERER_MSP_ADMIN_PK"

ORDERER_MSP_ADMIN_CERT=`jq -r .ORDERER_MSP_ADMIN_CERT "$CONFIG_FILE"`
#log "ORDERER_MSP_ADMIN_CERT is: $ORDERER_MSP_ADMIN_CERT"




ORDERER_NODE_TLS_PK=`jq -r .ORDERER_NODE_TLS_PK "$CONFIG_FILE"`
#log "ORDERER_NODE_TLS_PK is: $ORDERER_NODE_TLS_PK"

ORDERER_NODE_TLS_SIGNCERT=`jq -r .ORDERER_NODE_TLS_SIGNCERT "$CONFIG_FILE"`
#log "ORDERER_NODE_TLS_SIGNCERT is: $ORDERER_NODE_TLS_SIGNCERT"

ORDERER_MSP_ROOT_TLSCA_CERT=`jq -r .ORDERER_MSP_ROOT_TLSCA_CERT "$CONFIG_FILE"`
#log "ORDERER_MSP_ROOT_TLSCA_CERT is: $ORDERER_MSP_ROOT_TLSCA_CERT"




log "################ Create Orderer MSP config file for IBP ################" 
(
cat<<EOF
{
    "display_name": "$ORG_DISPLAY_NAME",
    "msp_id": "$MSP_ID",
    "type": "msp",
    "admins": [
        "$ORDERER_MSP_ADMIN_CERT"
    ],
    "root_certs": [
        "$ORDERER_MSP_ROOT_CA_CERT"
    ],
    "intermediate_certs": [],
    "tls_root_certs": [
        "$ORDERER_MSP_ROOT_TLSCA_CERT"
    ],
    "host_url": "$IBP_CONSOLE_URL",
    "name": "$ORG_NAME"
}
EOF
)> ./IBPconfig/configOrdererOrgMSP.json




log "################ Create Orderer Node config file for IBP ################" 
(
cat<<EOF
{
    "system_channel_id": "$SYSTEM_CHANNEL_ID",
    "cluster_id": "$CLUSTER_ID",
    "orderer_type": "raft",
    "msp_id": "$MSP_ID",
    "config": 
        {
            "msp": {
                "component": {
                    "keystore": "$ORDERER_NODE_PK",
                    "signcerts": "$ORDERER_NODE_SIGNCERT",
                    "cacerts": ["$ORDERER_MSP_ROOT_CA_CERT"],
                    "intermediatecerts": [],
                    "admincerts": ["$ORDERER_MSP_ADMIN_CERT"]
                },
                "tls": {
                    "keystore": "$ORDERER_NODE_TLS_PK",
                    "signcerts": "$ORDERER_NODE_TLS_SIGNCERT",
                    "cacerts": ["$ORDERER_MSP_ROOT_TLSCA_CERT"],
                    "intermediatecerts": [],
                    "admincerts": ["$ORDERER_MSP_ADMIN_CERT"]
                }
            }
        }
    ,
    "cluster_name": "$ORDERER_CLUSTER_NAME",
    "display_name": "$ORDERER_DISPLAY_NAME"
}
EOF
)> ./IBPconfig/configCreateOrdererNodeV1.json



log "################ Create Orderer Org Admin identity config file for IBP Console wallet (can't be API added) ################" 
(
cat<<EOF
{
    "name": "OrdererOrgMspAdmin",
    "type": "identity",
    "private_key": "$ORDERER_MSP_ADMIN_PK",
    "cert": "$ORDERER_MSP_ADMIN_CERT"
}
EOF
)> ./IBPconfig/configOrdererOrgAdminIBPwallet.json


