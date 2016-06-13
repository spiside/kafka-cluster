#!/bin/bash

cmd=${1:-help}
script=$(basename $0)
projectname=kafkacluster
kafka_image=spiside/kafka-cluster

if [ "$cmd" == "help" ]; then
    cat <<EOF
$script - A helpful CLI for wrapping commands

    bootstrap
        Starts up the kafka cluster using docker-compose, scales up to two
        kafka nodes, and creates a topic 'test'. 
    down
        Stops the running containers and removes the stopped containers.
    logs [-f, --follow]
        Outputs the cluster logs to STDOUT.
    scale <# of nodes>
        Scales up the the kafka nodes to the number of nodes entered.
    shell <container_id:optional>
        Runs a kafka container and drops you in a shell. If a container id
        is specified, runs bash in the supplied container.
    stop
        Stops the running containers.
    up
        Starts up the kafka cluster and recreates the containers.

EOF
    exit
fi

docker_compose() {
    docker-compose -p $projectname "$@"
}

case $cmd in
    bootstrap)
        # Check that the image exists and, if not, pull it.
        docker inspect spiside/kafka-cluster &> /dev/null
        if [ $? -ne 0 ]; then
            echo "Docker image doesn't exist, pulling..."
            docker pull $kafka_image
        fi

        set -e
        # Start up the containers.
        docker_compose up -d --force-recreate
        docker_compose scale kafka=2
        sleep 3  # wait for kafka to start.
        echo 'bash $KAFKA_HOME/bin/kafka-topics.sh --create --topic test --partitions 2 --replication-factor 2 --zookeeper zookeeper:2181' \
             | docker run --net=$projectname\_default -e RUN_TYPE=manual -a stdin -i $kafka_image &> /dev/null
        echo "Wrote topic 'test'"
        echo "Bootstrap ran successfully!"
        set +e
        ;;

    down|stop)
        docker_compose $1
        ;;

    logs)
        docker_compose "$@"
        ;;

    scale)
        shift
        docker_compose scale kafka=$1
        ;;

    shell)
        shift
        if [ ! -z $1 ]; then
            docker exec -it $1 bash
            exit 0
        fi
        docker run --net=$projectname\_default -e RUN_TYPE=manual -e ZOOKEEPER_URL=zookeeper:2181 --hostname kafka-shell -it $kafka_image
        ;;

    up)
        docker_compose up -d --force-recreate
        ;;

    *)
        echo "$@ is not a vaild command. Enter '$script help' for a list of commands."
        ;;
esac
