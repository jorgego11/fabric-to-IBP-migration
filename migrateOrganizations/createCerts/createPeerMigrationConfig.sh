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

export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)


# Remove previous install
rm -r ./peerCerts

# Create new install
mkdir ./peerCerts
mkdir ./peerCerts/ca ./peerCerts/tlsca


log "################ Lets do Peer Org - Root CA ################"  
cd ./peerCerts/ca

mkdir certs crl newcerts private csr
chmod 700 private
touch index.txt
echo 1000 > serial

cp ../../../../crypto-config/Admin@aptalkarga.tr/msp/keystore/ca.key.pem     ./private/ca.key.pem 
cp ../../../../crypto-config/Admin@aptalkarga.tr/msp/cacerts/ca.aptalkarga.tr-cert.pem  ./certs/ca.cert.pem
PEER_MSP_ROOT_CA_CERT=`cat ./certs/ca.cert.pem | base64 $FLAG`



log "################ Lets do Peer Org - Root TLS CA ################" 
cd ../..
cd ./peerCerts/tlsca

mkdir certs crl newcerts private csr
chmod 700 private
touch index.txt
echo 1000 > serial

cp ../../../../crypto-config/Admin@aptalkarga.tr/msp/keystore/tlsca.key.pem   ./private/tlsca.key.pem 
cp ../../../../crypto-config/Admin@aptalkarga.tr/msp/tlscacerts/tlsca.aptalkarga.tr-cert.pem  ./certs/tlsca.cert.pem
PEER_MSP_ROOT_TLSCA_CERT=`cat ./certs/tlsca.cert.pem | base64 $FLAG`



log "################ Lets do Peer Org - MSP Admin identity certificate ################" 
cd ../..
cd ./peerCerts/ca

cp ../../../../crypto-config/Admin@aptalkarga.tr/msp/keystore/mspadmin.key.pem   ./private/mspadmin.key.pem
cp ../../../../crypto-config/Admin@aptalkarga.tr/msp/signcerts/Admin@aptalkarga.tr-cert.pem  ./certs/mspadmin.cert.pem

# PEER_MSP_ADMIN_CERT Base64 encode
PEER_MSP_ADMIN_CERT=`cat ./certs/mspadmin.cert.pem | base64 $FLAG`
PEER_MSP_ADMIN_PK=`cat ./private/mspadmin.key.pem | base64 $FLAG`




log "################ Lets do new Peer Node identity (signcert & private key) ################" 
cd ../..
cd ./peerCerts/ca
cp ../../ssl-config/opensslPeer.cnf .

# Create the Peer identity private key
# private key is not encripted, otherwise add    -aes128 | -aes192 | -aes256 | -des | -des3    -passout <passpharse>
openssl ecparam -genkey -name prime256v1 -noout -out ./private/peer.key.PKCS1.pem

openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./private/peer.key.PKCS1.pem -out ./private/peer.key.pem
PEER_NODE_PK=`cat ./private/peer.key.pem | base64 $FLAG`


# Create the MSP Admin Certificate Signing Request (CSR)
openssl req -config opensslPeer.cnf \
      -key private/peer.key.pem \
      -batch -new -sha256 -out csr/peer.csr.pem 

# Sign the CSR 
openssl ca -config opensslPeer.cnf \
      -extensions usr_cert \
      -days 375 -notext -md sha256 \
      -in csr/peer.csr.pem \
      -out certs/peer.cert.pem

PEER_NODE_SIGNCERT=`cat ./certs/peer.cert.pem | base64 $FLAG`

# Verify the root CA certificate
openssl x509 -noout -text -in certs/peer.cert.pem

#Verify certificate chain of trust 
log "##### Certificate chain of trust validation" 
openssl verify -purpose any -CAfile certs/ca.cert.pem      certs/peer.cert.pem
log "##### " 



log "################ Create new Peer Node public TLS certificate ################" 
cd ../..
cd ./peerCerts/tlsca
cp ../../ssl-config/opensslPeerTLS.cnf .

# Create the Peer TLS private key
# private key is not encripted, otherwise add    -aes128 | -aes192 | -aes256 | -des | -des3    -passout <passpharse>
openssl ecparam -genkey -name prime256v1 -noout -out ./private/tlspeer.key.PKCS1.pem

openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./private/tlspeer.key.PKCS1.pem -out ./private/tlspeer.key.pem
PEER_NODE_TLS_PK=`cat ./private/tlspeer.key.pem | base64 $FLAG`


# Create the Peer TLS   Certificate Signing Request (CSR)
openssl req -config opensslPeerTLS.cnf \
      -key private/tlspeer.key.pem \
      -batch -new -sha256 -out csr/tlspeer.csr.pem 

# Sign the CSR 
openssl ca -config opensslPeerTLS.cnf \
      -extensions server_cert \
      -days 375 -notext -md sha256 \
      -in csr/tlspeer.csr.pem \
      -out certs/tlspeer.cert.pem

PEER_NODE_TLS_SIGNCERT=`cat ./certs/tlspeer.cert.pem | base64 $FLAG`

# Verify the root CA certificate
openssl x509 -noout -text -in certs/tlspeer.cert.pem

#Verify certificate chain of trust 
log "##### Certificate chain of trust validation" 
openssl verify -purpose any -CAfile certs/tlsca.cert.pem      certs/tlspeer.cert.pem
log "##### " 






# Back to peerCerts folder
cd ..

log "################ Create Peer migration config file ################" 
(
cat<<EOF
{
    "ORG_DISPLAY_NAME": "KargaMSP",
    "ORG_NAME": "KargaMSP",
    "MSP_ID": "KargaMSP",
    "IBP_CONSOLE_URL": "https://ibp-jorge-ibpconsole-console.mycluster-dal12-bd8e586d66eff81119bfe4722b13dbd4-0000.us-south.containers.appdomain.cloud:443",
    "PEER_STATE_DB": "couchdb",
    "PEER_DISPLAY_NAME": "peeribp2",
            "PEER_NODE_PK": "$PEER_NODE_PK",
            "PEER_NODE_SIGNCERT": "$PEER_NODE_SIGNCERT",
            "PEER_MSP_ROOT_CA_CERT": "$PEER_MSP_ROOT_CA_CERT",
    "PEER_MSP_ADMIN_PK": "$PEER_MSP_ADMIN_PK",          
    "PEER_MSP_ADMIN_CERT": "$PEER_MSP_ADMIN_CERT",
            "PEER_NODE_TLS_PK": "$PEER_NODE_TLS_PK",
            "PEER_NODE_TLS_SIGNCERT": "$PEER_NODE_TLS_SIGNCERT",
            "PEER_MSP_ROOT_TLSCA_CERT": "$PEER_MSP_ROOT_TLSCA_CERT"
}
EOF
)> peerMigrationConfig.json
