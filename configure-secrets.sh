#!/bin/bash
set -e

echo 'Configure Secrets'
echo '-----------------'

echo "Please provide ..."
read -sp "- the password for the Mosquitto Telegraf user: " telegrafPassword && echo
read -sp "- a password for InfluxDB: " influxPassword && echo
read -sp "- a access token for InfluxDB: " influxAccessToken && echo
read -sp "- a password for Grafana: " grafanaPassword && echo

export MQTT_BROKER_TELEGRAF_PASSWORD=$telegrafPassword
export INFLUXDB_PASSWORD=$influxPassword
export INFLUXDB_ACCESS_TOKEN=$influxAccessToken
export GRAFANA_PASSWORD=$grafanaPassword

echo -n 'Configuring config/secrets.tfvars ...'
envsubst < config/secrets.tfvars.template > config/secrets.tfvars
echo ' done.'

echo "Secrets successfully configured. Please refer to the README for the next steps."
