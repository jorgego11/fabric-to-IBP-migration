# Upgrade HL Fabric

## Assumptions and considerations

The assumption is that we have a HL Fabric v1.x network with a Kafka Orderer that will be upgraded to v2.x. After this is complete, we can proceed to the next step, which is transition every channel from using Kafka-based ordering services to Raft-based ordering services. This will be accomplished through a series of configuration update transactions on each channel in the network.

At a high level, the process is inspired by the official Fabric documentation described here 
https://hyperledger-fabric.readthedocs.io/en/release-2.1/upgrade.html


