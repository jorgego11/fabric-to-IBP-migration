# HL Fabric to IBP Migration Asset

## Why this asset?

There is an expectation that as the IBM Blockchain Platform (IBP) matures there will be a growing number of HL Fabric networks in production that eventually will migrate to IBP. The intention of this asset is to support a new Expert Labs "Fabric to IBP Migration Offering" in a way that Expert Labs resources can execute the delivery of this offering in a consistent repeatable manner with low risk and a high chance of success. The asset consists of three things: a proven migration `process`, a set of `scripts` and related `documentation`.

## Migration Process

There is a separate folder with a Readme file and scripts for each step of the migration process. Note that not all steps are required. For example, some Fabric networks may be using a Raft based Orderer already. The migration steps are:

1. Upgrade the HL Fabric version (coming soon)
2. Upgrade Orderer from Kafka to Raft (coming soon)
3. [Migrate Orderer and Organization nodes](migrateOrganizations/README.md)


## Known Limitations

* At this time, there is no explicit support for Private Data Collections
* The current use assumes that the source Fabric Network uses an external CA. A similar process can be used for networks that use FabricCA. 
* There could be potential problems for new peers in IBP per https://jira.hyperledger.org/browse/FAB-5288 (need to check how the Enterprise->v2 Migration Tool avoid this)

## IBP Problems Found

* IBP v2 Orderer Node creation API does not work.  I had to use v1 which is undocumented
* The IBP Peer Node creation API has some parameters that don’t work for the 4/16 fix release
* IBP does not support custom consortium names in system channel configuration block. It only works the name SampleConsortium. A pending fix has been created for this. 


