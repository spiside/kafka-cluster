# Kafka and Zookeeper Image
# Kafka version 0.10.0.0 
FROM java:openjdk-8-jre

MAINTAINER Spiro Sideris <spirosideris@gmail.com>
LABEL dscription="Zookeeper and Kafka Base Image"

ENV DEBIAN_FRONTEND noninteractive
ENV SCALA_VERSION 2.11
ENV KAFKA_VERSION 0.10.0.0
ENV KAFKA_HOME /opt/kafka

# Update the base image and make sure all sources and packages are up to date.
RUN apt-get update && apt-get -q -y upgrade && apt-get clean 
# Install zookeeper and kafka.
RUN apt-get install -y zookeeper && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    wget -q http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && mkdir /opt/kafka && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt/kafka --strip-components 1 && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

COPY ./scripts/run.sh /bin/

ENTRYPOINT ["run.sh"]
