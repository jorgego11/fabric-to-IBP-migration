# Upgrade HL Fabric

## Assumptions and considerations

The assumption is that we have a HL Fabric v1.3 network with a Kafka Orderer that will be upgraded to v1.4. After this is complete, we can proceed to the next step, which is transition every channel from using Kafka-based ordering services to Raft-based ordering services. 

At a high level, the process is inspired by the official Fabric documentation described here 
https://hyperledger-fabric.readthedocs.io/en/release-2.1/upgrade.html


## Upgrade process 

* Stop the network. Back up ledgers and MSPs.
* Upgrade the binaries for the ordering service, the Fabric CA, and the peers. These upgrades may be done in parallel.
* Upgrade client SDKs.
* Restart the network and test. 
* If upgrading to v1.4.2, enable the v1.4.2 channel capabilities. This will be accomplished through a series of configuration update transactions on each channel in the network.



