#!/bin/bash
set -e

echo 'Set and Encode Mosquitto Passwords'
echo '----------------------------------'

echo "Please provide passwords for ..."
read -sp "- Mosquitto Sensor password: " sensorPassword && echo
read -sp "- Mosquitto Telegraf password: " telegrafPassword && echo

export MQTT_BROKER_SENSOR_PASSWORD=$sensorPassword
export MQTT_BROKER_TELEGRAF_PASSWORD=$telegrafPassword

echo -n "Configuring container/config/mosquitto.passwd.raw ..."
envsubst < config/mosquitto.passwd.template > config/mosquitto.passwd.raw
echo ' done.'

echo -n "Encrypting mosquitto passwords into container/config/mosquitto.passwd ..."
MOSQUITTO_IMAGE=eclipse-mosquitto:2.0
CONTAINER_NAME=mosquitto-setup-cli

# Remove container on error
trap "docker rm --force $CONTAINER_NAME" SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM

docker run  --name $CONTAINER_NAME -itd $MOSQUITTO_IMAGE 1> /dev/null
docker cp   config/mosquitto.passwd.raw $CONTAINER_NAME:mosquitto.passwd
docker exec $CONTAINER_NAME mosquitto_passwd -U mosquitto.passwd
docker cp   $CONTAINER_NAME:mosquitto.passwd config/mosquitto.passwd
echo ' done.'

echo -n 'Removing intermediary file ...'
rm ./config/mosquitto.passwd.raw
echo ' done.'

echo -n "Removing $CONTAINER_NAME container ..."
docker rm --force $CONTAINER_NAME 1> /dev/null
echo ' done.'

read -p "Would you also like to remove the local image $MOSQUITTO_IMAGE (y/n)? " -n 1
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    docker rmi $MOSQUITTO_IMAGE
fi

echo "Setup complete. Please refer to the README for the next steps."
