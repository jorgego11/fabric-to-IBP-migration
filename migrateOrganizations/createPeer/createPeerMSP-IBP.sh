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




API_KEY=`jq -r .API_KEY "$CONFIG_FILE"`
log "API_KEY is: $API_KEY"

API_SECRET=`jq -r .API_SECRET "$CONFIG_FILE"`
log "API_SECRET is: $API_SECRET"

IBP_CONSOLE_URL=`jq -r .IBP_CONSOLE_URL "$CONFIG_FILE"`
log "IBP_CONSOLE_URL is: $IBP_CONSOLE_URL"


#######  Create Peer Org MSP in IBP

curl --insecure -X POST "$IBP_CONSOLE_URL/ak/api/v2/components/msp" \
--header "Content-Type: application/json" \
--user "$API_KEY":"$API_SECRET"  \
--data-binary "@./IBPconfig/configPeerOrgMSP.json" 


