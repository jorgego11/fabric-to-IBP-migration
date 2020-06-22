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
rm -r ./ordererCerts

# Create new install
mkdir ./ordererCerts
mkdir ./ordererCerts/ca ./ordererCerts/tlsca


log "################ Lets do Orderer Org - Root CA ################"  
cd ./ordererCerts/ca

mkdir certs crl newcerts private csr
chmod 700 private
touch index.txt
echo 1000 > serial

cp ../../../../crypto-config/GroeifabriekMSP-Admin/msp/keystore/ca.key.pem  ./private/ca.key.pem 
cp ../../../../crypto-config/GroeifabriekMSP-Admin/msp/cacerts/ca.groeifabriek.nl-cert.pem  ./certs/ca.cert.pem
ORDERER_MSP_ROOT_CA_CERT=`cat ./certs/ca.cert.pem | base64 $FLAG`



log "################ Lets do Orderer Org - Root TLS CA ################" 
cd ../..
cd ./ordererCerts/tlsca

mkdir certs crl newcerts private csr
chmod 700 private
touch index.txt
echo 1000 > serial

cp ../../../../crypto-config/GroeifabriekMSP-Admin/msp/keystore/tlsca.key.pem   ./private/tlsca.key.pem 
cp ../../../../crypto-config/GroeifabriekMSP-Admin/msp/tlscacerts/tlsca.groeifabriek.nl-cert.pem  ./certs/tlsca.cert.pem
ORDERER_MSP_ROOT_TLSCA_CERT=`cat ./certs/tlsca.cert.pem | base64 $FLAG`



log "################ Lets do Orderer Org - MSP Admin identity certificate ################" 
cd ../..
cd ./ordererCerts/ca

cp ../../../../crypto-config/GroeifabriekMSP-Admin/msp/keystore/mspadmin.key.pem  ./private/mspadmin.key.pem
cp ../../../../crypto-config/GroeifabriekMSP-Admin/msp/signcerts/Admin@groeifabriek.nl-cert.pem  ./certs/mspadmin.cert.pem

# ORDERER_MSP_ADMIN_CERT Base64 encode
ORDERER_MSP_ADMIN_CERT=`cat ./certs/mspadmin.cert.pem | base64 $FLAG`
ORDERER_MSP_ADMIN_PK=`cat ./private/mspadmin.key.pem | base64 $FLAG`






log "################ Lets do new Orderer Node identity (signcert & private key) ################" 
cd ../..
cd ./ordererCerts/ca
cp ../../ssl-config/opensslOrderer.cnf .

# Create the Orderer identity private key
# private key is not encripted, otherwise add    -aes128 | -aes192 | -aes256 | -des | -des3    -passout <passpharse>
openssl ecparam -genkey -name prime256v1 -noout -out ./private/orderer.key.PKCS1.pem

openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./private/orderer.key.PKCS1.pem -out ./private/orderer.key.pem
ORDERER_NODE_PK=`cat ./private/orderer.key.pem | base64 $FLAG`


# Create the MSP Admin Certificate Signing Request (CSR)
openssl req -config opensslOrderer.cnf \
      -key private/orderer.key.pem \
      -batch -new -sha256 -out csr/orderer.csr.pem 

# Sign the CSR 
openssl ca -config opensslOrderer.cnf \
      -extensions usr_cert \
      -days 375 -notext -md sha256 \
      -in csr/orderer.csr.pem \
      -out certs/orderer.cert.pem

ORDERER_NODE_SIGNCERT=`cat ./certs/orderer.cert.pem | base64 $FLAG`

# Verify the root CA certificate
openssl x509 -noout -text -in certs/orderer.cert.pem

#Verify certificate chain of trust 
log "##### Certificate chain of trust validation" 
openssl verify -purpose any -CAfile certs/ca.cert.pem      certs/orderer.cert.pem
log "##### " 



log "################ Create new Orderer Node public TLS certificate ################" 
cd ../..
cd ./ordererCerts/tlsca
cp ../../ssl-config/opensslOrdererTLS.cnf .

# Create the Orderer TLS private key
# private key is not encripted, otherwise add    -aes128 | -aes192 | -aes256 | -des | -des3    -passout <passpharse>
openssl ecparam -genkey -name prime256v1 -noout -out ./private/tlsorderer.key.PKCS1.pem

openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./private/tlsorderer.key.PKCS1.pem -out ./private/tlsorderer.key.pem
ORDERER_NODE_TLS_PK=`cat ./private/tlsorderer.key.pem | base64 $FLAG`


# Create the Orderer TLS   Certificate Signing Request (CSR)
openssl req -config opensslOrdererTLS.cnf \
      -key private/tlsorderer.key.pem \
      -batch -new -sha256 -out csr/tlsorderer.csr.pem 

# Sign the CSR 
openssl ca -config opensslOrdererTLS.cnf \
      -extensions server_cert \
      -days 375 -notext -md sha256 \
      -in csr/tlsorderer.csr.pem \
      -out certs/tlsorderer.cert.pem

ORDERER_NODE_TLS_SIGNCERT=`cat ./certs/tlsorderer.cert.pem | base64 $FLAG`

# Verify the root CA certificate
openssl x509 -noout -text -in certs/tlsorderer.cert.pem

#Verify certificate chain of trust 
log "##### Certificate chain of trust validation" 
openssl verify -purpose any -CAfile certs/tlsca.cert.pem      certs/tlsorderer.cert.pem
log "##### " 






# Back to ordererCerts
cd ..

log "################ Create Orderer migration config file ################" 
(
cat<<EOF
{
    "ORG_DISPLAY_NAME": "GroeifabriekMSP",
    "ORG_NAME": "Orderer Org",
    "MSP_ID": "GroeifabriekMSP",
    "IBP_CONSOLE_URL": "https://ibp-jorge-ibpconsole-console.mycluster-dal12-bd8e586d66eff81119bfe4722b13dbd4-0000.us-south.containers.appdomain.cloud:443",
    "SYSTEM_CHANNEL_ID": "testchainid",
    "CLUSTER_ID": "ibpraftcluster",
    "ORDERER_CLUSTER_NAME": "ordservicemig",
    "ORDERER_DISPLAY_NAME": "ordservicemig",
            "ORDERER_NODE_PK": "$ORDERER_NODE_PK",
            "ORDERER_NODE_SIGNCERT": "$ORDERER_NODE_SIGNCERT",
            "ORDERER_MSP_ROOT_CA_CERT": "$ORDERER_MSP_ROOT_CA_CERT",
    "ORDERER_MSP_ADMIN_PK": "ORDERER_MSP_ADMIN_PK",
    "ORDERER_MSP_ADMIN_CERT": "$ORDERER_MSP_ADMIN_CERT",
            "ORDERER_NODE_TLS_PK": "$ORDERER_NODE_TLS_PK",
            "ORDERER_NODE_TLS_SIGNCERT": "$ORDERER_NODE_TLS_SIGNCERT",
            "ORDERER_MSP_ROOT_TLSCA_CERT": "$ORDERER_MSP_ROOT_TLSCA_CERT"
}
EOF
)> ordererMigrationConfig.json
