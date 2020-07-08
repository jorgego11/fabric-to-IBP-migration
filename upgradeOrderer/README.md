# Upgrade Orderer

## Assumptions and Considerations

The assumption is that we have a HL Fabric v1.x network with a Kafka Orderer. We will transition every channel from using Kafka-based ordering services to Raft-based ordering services. This will be accomplished through a series of configuration update transactions on each channel in the network. Note that migration is done in place, utilizing the existing ledgers for the existing deployed Kafka ordering nodes. In other words, the existing orderer nodes will become Raft consenters after the migration. Addition or removal of orderers should be performed after the migration.

The expectation is that the network is already fully configured for TLS. Otherwise, TLS must be fully enabled and tested before attempting upgrading the orderer to Raft. 

At a high level, the process follows the official Fabric documentation described here 
https://hyperledger-fabric.readthedocs.io/en/release-2.1/upgrade.html




## Entry to Maintenance Mode

Prior to setting the ordering service into maintenance mode, it is recommended that the peers and clients of the network be stopped.
Stop the peers and client apps. Depending on your Kubernetes deployment, you could try: 
```
kubectl scale deployment <peer-deployment-name> --replicas=0  -n <namespace>
kubectl scale statefulset <peer-stateful-set-name> --replicas=0  -n <namespace>
```
Update the script ``channelMaintenanceMode.sh`` with the right parameters and run it for each channel in the network, starting with the system channel.



##  Shut Down servers and Backup storage

Shut down all ordering nodes, Kafka servers, and Zookeeper servers, in this order. It is important to shutdown the ordering service nodes first. 
Create a backup of the file system of these servers. 
Then restart Zookeeper server, Kafka service and then the ordering service nodes, in this order.


## Switch to Raft

The next step in the migration process is another channel configuration update for each channel. 

Update the script ``channelRaftSwitch.sh`` with the right parameters and run it for each channel in the network, starting with the system channel.

Make sure you have all the environment variables requires by Raft as defined in the Fabric documentation

## Restart and Validate Leader

After the ConsensusType update has been completed on each channel, stop all ordering service nodes, stop all Kafka brokers and Zookeepers, and then restart only the ordering service nodes. They should restart as Raft nodes, form a cluster per channel, and elect a leader on each channel.

Note: Since Raft-based ordering service requires mutual TLS between orderer nodes, additional configurations are required before you start them again.

## Switch Back to Normal Mode

Perform another channel configuration update on each channel (sending the config update to the same ordering node you have been sending configuration updates to until now), switching the State from STATE_MAINTENANCE to STATE_NORMAL. Start with the system channel, as usual. 
Update the script ``channelMaintenanceMode.sh`` with the right parameters and run it for each channel in the network, starting with the system channel.


## Potential Problems

Its very important to have a working TLS configuration before the migration and during the step where the consensus type is changed to Raft. In particular, make sure you followed the recommendations in this section 
https://hyperledger-fabric.readthedocs.io/en/release-1.4/raft_configuration.html#local-configuration