# Kafka Cluster with Docker

```
A tool for creating a Kafka cluster with a single Zookeeper node.
Uses Kafka version 0.10.0.
```

## Setup

Before starting the cluster you will need to install docker
(docker-engine >= 0.10.0) and docker-compose. If you already have these
installed, you can skip to [Getting Started](#getting-started).


### Setting up Docker

You can install docker from [here](https://docs.docker.com/engine/installation/).

Once you have docker installed, you can install docker-compose [here](https://docs.docker.com/compose/install/)

**NB**: If you are not in the [docker beta program](https://blog.docker.com/2016/03/docker-for-mac-windows-beta/)
and are currently using macOS or Windows, you will need to setup a `docker-machine` VM to create the cluster. To learn
more, I highly recommend reading the [documentation](https://docs.docker.com/machine/get-started/)
before moving on.


## Getting Started

With docker and docker-compose installed, the simplest way to get the cluster
up and running is to run the bootstrap command. The bootstrap command will
launch a 2 node Kafka cluster with a single Zookeeper node and create a Kafka
topic `test` with 2 partitions plus a replication factor of 2. You can run the
command by entering the following in your shell:

```
./kafka-cluster.sh bootstrap
```

You should see a success message if the bootstrap command ran successfully. To
check and see if the docker containers are running, run the following

```
docker ps --filter "name=kafkacluster"
```

There should be three containers running where two will be named
`kafkacluster_kafka_<id>` and one named `kafkacluster_zookeeper_<id>`.

At this point, you can start interacting with the cluster!


### Connecting to the cluster

The cluster will currently be running in a docker network (defaults to
kafkacluster_default), which means the easiest way of interacting with it
is to attach a docker container to the network. The easiest way is to run
the `shell` command which will drop you into the shell of a running container.

```
./kafka-cluster.sh shell
```

From here, we can start interacting with the zookeeper and kafka nodes.


### Managing Kafka Topics

_The rest of the tutorial assumes you have ran the `bootstrap` command._


#### Describing the topic

If you recall from the `bootstrap` command, we created a topic `test` as the
final step. You can inspect the topic using the `describe` option with the
kafka topic script.

```
$KAFKA_HOME/bin/kafka-topics.sh --describe --topic test --zookeeper $ZOOKEEPER_URL
```

You should see something similar to following output (with different broker ids):

```
Topic:test      PartitionCount:2        ReplicationFactor:2     Configs:
        Topic: test     Partition: 0    Leader: 437     Replicas: 437,979       Isr: 437,979
        Topic: test     Partition: 1    Leader: 979     Replicas: 979,437       Isr: 979,437k
```

Awesome! Now let's start publishing and reading from the topic.


#### Publishing and Subscribing to the topic

Open up two seperate terminals and enter only one of the following commands in each:

_In terminal 1 (producer)_
```
./kafka-cluster.sh shell  # wait for the shell to start
$KAFKA_HOME/bin/kafka-console-producer.sh --topic test --broker-list kafka:9092
```

_In terminal 2 (consumer)_
```
./kafka-cluster.sh shell  # wait for the shell to start
$KAFKA_HOME/bin/kafka-console-consumer.sh --topic test --zookeeper $ZOOKEEPER_URL
```

Both terminals should now be waiting to send and receive to each other. To test that they
work, in your terminal 1 (the producer), type `hello world!`. In terminal 2 (the consumer)
you should see the text pop up like this:

```
root@<container-id>:/# $KAFKA_HOME/bin/kafka-console-consumer.sh --topic test --zookeeper $ZOOKEEPER_URL
hello world!
```


#### Creating a topic

To create a topic, you can use the same kafka topics script that we used earlier to
describe the `test` topic. In this example, we are going to create an `example` topic
with replication factor of 2 (since RF <= # of Kafka nodes) and 4 partitions.

```
$KAFKA_HOME/bin/kafka-topics.sh --create --topic example --partitions 4 --replication-factor 2 --zookeeper $ZOOKEEPER_URL 
```

After creating the topic, you can describe it using the previous describe command

```
$KAFKA_HOME/bin/kafka-topics.sh --describe --topic example --zookeeper $ZOOKEEPER_URL
```


## List of helpful commands

Some environment variables in the cluster:
* `KAFKA_HOME`: The directory containing the Kafka library.
* `ZOOKEEPER_URL`: The `<host>:<port>` for the Zookeeper node.


### Cluster Ops

Starts up the cluster with a default single kafka and zookeeper node.
```
./kafka-cluster.sh up
```

Scale up the kafka nodes. In this example it will increase kafka nodes to 4.
```
./kafka-cluster.sh scale 4
```

Stop the cluster.
```
./kafka-cluster.sh stop
```

Stops the cluster then removes the stopped containers (recommended).
```
./kafka-cluster.sh cleanup
```

### Debugging

Displays the cluster logs.
```
./kafka-cluster.sh logs
```
Or follow them with:
```
./kafka-cluster.sh logs -f
```
