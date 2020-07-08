# Upgrade Orderer

## Assumptions and Considerations

The assumption is that we have a HL Fabric network with a Kafka Orderer. We will transition every channel from using Kafka-based ordering services to Raft-based ordering services. This will be accomplished through a series of configuration update transactions on each channel in the network. Note that migration is done in place, utilizing the existing ledgers for the existing deployed Kafka ordering nodes. In other words, the existing orderer nodes will become Raft consenters after the migration. Addition or removal of orderers should be performed after the migration.

At a high level, the process follows the official Fabric documentation described here 
https://hyperledger-fabric.readthedocs.io/en/release-2.1/upgrade.html




## Entry to Maintenance Mode

Prior to setting the ordering service into maintenance mode, it is recommended that the peers and clients of the network be stopped.
Stop the peers and client apps. Depending on your Kubernetes deployment, you could try: 
```
kubectl scale deployment <peer-deployment-name> --replicas=0  -n <namespace>
kubectl scale statefulset <peer-stateful-set-name> --replicas=0  -n <namespace>
```
Update the script ``channelMaintenanceMode.sh`` with the right parameters for your environment and run it for each channel in the network, starting with the **system channel**.


##  Shut Down nodes, Backup, Restart

Shut down all ordering nodes, Kafka servers, and Zookeeper servers, in this order. It is important to shutdown the ordering service nodes first. 
Create a backup of the file system of these servers. 
Then restart Zookeeper server, Kafka service and then the ordering service nodes, in this order.


## Switch to Raft

The next step in the migration process is another channel configuration update for each channel. 

Update the script ``channelRaftSwitch.sh`` with the right parameters for your environment and run it for each channel in the network, starting with the **system channel**.

Note: make sure you have all the environment variables requires by Raft Orderer Pods/Containers as defined in the Fabric documentation. Since Raft-based ordering service requires mutual TLS between orderer nodes, additional configurations are required before you start them again. In particular, make sure you followed the recommendations in this section https://hyperledger-fabric.readthedocs.io/en/release-1.4/raft_configuration.html#local-configuration

## Restart and Validate Leader

After the ConsensusType update has been completed on each channel, stop all ordering service nodes, stop all Kafka brokers and Zookeepers, and then restart only the ordering service nodes. Check the logs of each orderer node, they should restart as Raft nodes, form a cluster per channel, and elect a leader on each channel.

## Switch Back to Normal Mode

Perform another channel configuration update on each channel (sending the config update to the same ordering node you have been sending configuration updates to until now), switching the State from STATE_MAINTENANCE to STATE_NORMAL. Update the script ``channelMaintenanceMode.sh`` with the right parameters based on your environment and run it for each channel in the network, starting with the **system channel**.




## Lessons Learned

A Kafka based orderer does not require TLS. Therefore, there is a chance that you will find in the field a production network not using TLS. This will add additional work to the migration process. The recommendation is that TLS must be fully enabled and tested `before` attempting upgrading the orderer to Raft. Enabling TLS may require to create new identities for each orderer node.

Orderer Pods configuration may need to be changed to reflect the TLS configuration and new environment variables required by Raft. 

Most probably the production network is running on Docker Compose or a Kubernetes cluster. Depending on the actual networking configuration, significant changes may be needed to allow consenters to connect with each other and peers to connect to each individual consenter.

In summary, the migration process is simple enough by using the tools provided in this repo. The real complexity comes from these other areas mentioned here: TLS conversion, new identities creation, manual updates to the pod/container definition and Docker Compose/Kubernetes networking reconfiguration. Hence, you may want to execute this work on a staging environment first with an end to end planning for the different tasks, before attempting in production. 