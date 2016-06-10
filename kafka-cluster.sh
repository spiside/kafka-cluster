#!/bin/bash

cmd=${1:-help}
script=$(basename $0)
projectname=kafkacluster

if [ "$cmd" == "help" ]; then
    cat <<EOF
$script - A helpful CLI for wrapping commands

    bootstrap
        Starts up the kafka cluster using docker-compose, scales up to two
        kafka nodes, and creates a topic 'test'. 
    cleanup
        Stops the running containers and removes the stopped containers.
    shell
        Runs a kafka container and drops you in a shell.
    stop
        Stops the running containers.

EOF
    exit
fi

case $cmd in
    bootstrap)
        # Check that the image exists and, if not, build it.
        docker inspect spiside/kafka-cluster &> /dev/null
        if [ $? -ne 0 ]; then
            echo "Docker image doesn't exist, pulling..."
            docker pull spiside/kafka-cluster
        fi

        # Start up the containers.
        docker-compose up -d --force-recreate
        docker-compose scale kafka=2
        sleep 3  # hack to wait for kafka to start.
        echo 'bash $KAFKA_HOME/bin/kafka-topics.sh --create --topic test --partitions 2 --replication-factor 2 --zookeeper zookeeper:2181' \
             | docker run --net=$projectname\_default -e RUN_TYPE=manual -a stdin -i kafkacluster_kafka &> /dev/null
        echo "Wrote topic 'test'"
        ;;

    cleanup)
        docker-compose stop && docker-compose rm -fa
        ;;

    shell)
        docker run --net=$projectname\_default -e RUN_TYPE=manual -it kafkacluster_kafka
        ;;

    start)
        docker-compose up -d --force-recreate
        ;;

    stop)
        docker-compose stop
        ;;

    *)
        echo "$@ is not a vaild command. Enter '$script help' for a list of commands."
        ;;
esac
