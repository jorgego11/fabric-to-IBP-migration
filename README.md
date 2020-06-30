# HL Fabric to IBP Migration Asset

## Why this asset?

There is an expectation that as the IBM Blockchain Platform (IBP) matures there will be a growing number of HL Fabric networks in production that eventually will migrate to IBP. The intention of this asset is to support a new Expert Labs "Fabric to IBP Migration Offering" in a way that Expert Labs resources can execute the delivery of this offering in a consistent repeatable manner with low risk and a high chance of success. The asset consists of three things: a proven migration `process`, a set of `scripts` and related `documentation`.

## Migration Process

There is a separate folder with a Readme file and scripts for each step of the migration process. Note that not all steps are required. For example, some Fabric networks may be using a Raft based Orderer already. The migration steps are:

1. Upgrade the HL Fabric version (coming soon)
2. Upgrade Orderer from Kafka to Raft (coming soon)
3. [Migrate Orderer and Organization nodes](migrateOrganizations/README.md)


## Channel Config Updates

The process of adding or removing consenters and peers and migrating from Kafka to Raft requires various channel configuration update transactions. We have two options to accomplish these channel updates. On a typical migration effort potentially these two options could be used together depending on the complexity of the migration effort.

### Channel Config Updates based on fabric-config library

There is a separate [repo](https://github.ibm.com/BlockchainLabs/fabric-config-updater) that contains different GO utilities that leverage the[fabric-config](https://github.com/hyperledger/fabric-config) library for most channel config updates. These are some of the updates that are currently supported (more comming soon):

* `encodeBlock` - Encodes a configuration block into a base64 string
* `addConsenter` - Adds a new orderer node as a consenter to the channel
* `changeChannelState` - Updates the state of the channel (normal or maintenance)
* `migrateKafkaToRaft` - Migrates the channel from Kafka to Raft
* `removeConsenter` - Removes orderer node/consenter from the channel


### Channel Config Updates based on Fabric CLI commands

Note that this option requires knowledge of the JSON structure that represents a channel configuration. This channel config update process consists basically of 3 steps: run a script to get the config block in JSON format, manually update channel config JSON file and run a script to submit the config update. The details of this process are described below: 

Change the directory to the folder `channelConfigUpdate` and complete the configuration file `channelBlock.json`. 

channelBlock.json explained
```
{
    "CHANNEL_NAME": "This is the channel id, typically for system channel will be testchainid, otherwise is the name of the application channel we want to update",
    "ORDERER_CONTAINER": "This is the orderer node URL in the source network that will receive the channle update commands",
    "ADMIN_TLSCA_CERT": "path to the pem TLS certificate for the organization admin",
    "FABRIC_PATH":      "path to the msp folder structure for the Orderer Org Admin that will submit channel update transactions ( ../../crypto-config/GroeifabriekMSP-Admin) ",
    "FABRIC_PATH_SIGN": "path to the msp folder structure for another Orderer Org Admin that will sign transactions based on the channel update policy ( ../../crypto-config/PivtMSP-Admin)"
}
```

 The following script will get the channel config json file in a way that is ready for manual updates.

```
./channelBlockGet.sh channelBlock.json
```

Now update the file `03config_blockTrimUPDATED.json` as needed. For example, add or remove a consenter node from the system or application channel. 

The following script will apply the updated configuration to the channel.

```
./channelBlockUpdate.sh channelBlock.json
```



## Asset Known Limitations

* At this time, there is no explicit support for Private Data Collections
* The current scenario assumes that the source Fabric Network uses an external CA. A similar process can be used for fabric networks that use FabricCA. 
* There could be potential problems for new peers in IBP per https://jira.hyperledger.org/browse/FAB-5288 (need to check how the Enterprise->v2 Migration Tool avoid this)

## IBP Problems Found

* IBP v2 Orderer Node creation API does not work.  I had to use v1 which is undocumented. A pending IBP fix has been created for this.
* The IBP Peer Node creation API has some parameters that don’t work for the 4/16 fix release. IBP releases beyond 4/16 fix this problem.
* IBP does not support custom consortium names in system channel configuration block. It only works the standard name SampleConsortium. A pending IBP fix has been created for this. 


