#!/usr/bin/env bash
set -e

: ${RUN_TYPE:? "Need RUN_TYPE to be configured."}

run_kafka() {
    # Set up the zookeeper url.
    if [ -z "$ZOOKEEPER_URL" ]; then
        ZOOKEEPER_URL=zookeeper:2181
    fi
    sed -ri "s/(zookeeper.connect)=(.*)/\1=$ZOOKEEPER_URL/g" $KAFKA_HOME/config/server.properties

    # Configure the broker id.
    if [ -z "$BROKER_ID" ]; then
        # Choose a random ID which has a 0.1% chance of collision.
        # TODO: Find a better way to determine broker ID for multi-cluster.
        BROKER_ID=$(($RANDOM % 1000))
    fi
    sed -ri "s/(broker.id)=(.*)/\1=$BROKER_ID/g" $KAFKA_HOME/config/server.properties

    # Configure the advertised listeners.
    if [ -z "$ADVERTISED_LISTENERS" ]; then
        # Defaults to the Docker networks's internal IP.
        ADVERTISED_LISTENERS="PLAINTEXT:\/\/$(cat /etc/hosts | grep $HOSTNAME | awk '{print $1}'):9092"
    fi
    sed -ri "s/#(advertised.listeners)=(.*)/\1=$ADVERTISED_LISTENERS/g" $KAFKA_HOME/config/server.properties

    $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
}

case "$RUN_TYPE" in
    zookeeper)
        $KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties
        ;;

    kafka)
        run_kafka
        ;;

    manual)
        bash $@
        ;;

    *)
        echo "Invalid run type: $RUN_TYPE"
        exit 1
        ;;
esac
