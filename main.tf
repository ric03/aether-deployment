terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.13.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "mosquitto" {
  name         = "eclipse-mosquitto:2.0"
  keep_locally = var.keep_images_locally
}
resource "docker_image" "telegraf" {
  name         = "telegraf:1.20"
  keep_locally = var.keep_images_locally
}
resource "docker_image" "influxdb" {
  name         = "influxdb:2.0"
  keep_locally = var.keep_images_locally
}
resource "docker_image" "grafana" {
  name         = "grafana/grafana:8.2.2"
  keep_locally = var.keep_images_locally
}

resource "docker_container" "mosquitto" {
  depends_on = [docker_network.mosquitto]
  image      = docker_image.mosquitto.latest
  name       = "mosquitto"
  ports {
    # TLS/SSL
    internal = 8883
    external = 8883
  }
  ports {
    # TCP/IP websockets
    internal = 9001
    external = 9001
  }
  volumes {
    container_path = "/mosquitto/config/mosquitto.conf"
    host_path      = abspath("config/mosquitto.conf")
  }
  volumes {
    container_path = "/mosquitto/config/mosquitto.passwd"
    host_path      = abspath("config/mosquitto.passwd")
  }
  networks_advanced {
    name = docker_network.mosquitto.name
  }
}

resource "docker_container" "telegraf" {
  depends_on = [docker_network.influxdb, docker_network.mosquitto]
  image      = docker_image.telegraf.latest
  name       = "telegraf"
  env        = [
    "INFLUXDB_ACCESS_TOKEN=${var.influxdb_access_token}",
    "MQTT_BROKER_TELEGRAF_PASSWORD=${var.mqtt_broker_telegraf_password}"
  ]
  volumes {
    container_path = "/etc/telegraf/telegraf.conf"
    host_path      = abspath("config/telegraf.conf")
    read_only      = true
  }
  networks_advanced {
    name = docker_network.influxdb.name
  }
  networks_advanced {
    name = docker_network.mosquitto.name
  }
}

resource "docker_container" "influxdb" {
  depends_on = [docker_network.influxdb]
  image      = docker_image.influxdb.latest
  name       = "influxdb"
  env        = [
    "DOCKER_INFLUXDB_INIT_MODE=setup",
    "DOCKER_INFLUXDB_INIT_USERNAME=home",
    "DOCKER_INFLUXDB_INIT_PASSWORD=${var.influxdb_password}",
    "DOCKER_INFLUXDB_INIT_ORG=home",
    "DOCKER_INFLUXDB_INIT_BUCKET=sensor-data",
    "DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=${var.influxdb_access_token}"
  ]
  ports {
    internal = 8086
    external = 8086
  }
  volumes {
    volume_name    = docker_volume.influxdb2-data.name
    container_path = "/var/lib/influxdb2"
  }
  networks_advanced {
    name = docker_network.influxdb.name
  }
}

resource "docker_volume" "influxdb2-data" {
  name = "influxdb2-data"
}

resource "docker_container" "grafana" {
  image = docker_image.grafana.latest
  name  = "grafana"
  env   = [
    "INFLUXDB_USERNAME=home",
    "INFLUXDB_ACCESS_TOKEN=${var.influxdb_access_token}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_password}"
  ]
  ports {
    internal = 3000
    external = 3000
  }
  volumes {
    container_path = "/etc/grafana/provisioning/datasources/influxdb.yml"
    host_path      = abspath("config/grafana_influxdb_datasource.yml")
    read_only      = true
  }
  volumes {
    container_path = "/etc/grafana/provisioning/dashboards/aether.json"
    host_path      = abspath("config/grafana-dashboard-aether.json")
    read_only      = true
  }
  networks_advanced {
    name = docker_network.influxdb.name
  }
}

resource "docker_network" "mosquitto" {
  name = "mosquitto"
}

resource "docker_network" "influxdb" {
  name = "influxdb"
}
