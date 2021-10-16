terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.13.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "mosquitto" {
  name         = "eclipse-mosquitto:2.0.12"
  keep_locally = var.keep_images_locally
}

resource "docker_container" "mosquitto" {
  image = docker_image.mosquitto.latest
  name  = "mosquitto"
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
    read_only      = true
  }
  volumes {
    container_path = "/mosquitto/config/mosquitto.passwd"
    host_path      = abspath("config/mosquitto.passwd")
    read_only      = true
  }
}


resource "docker_image" "telegraf" {
  name         = "telegraf:1.19.3"
  keep_locally = var.keep_images_locally
}

resource "docker_container" "telegraf" {
  image = docker_image.telegraf.latest
  name  = "telegraf"
  env = [
    "INFLUXDB_ACCESS_TOKEN=${var.influxdb_access_token}",
    "MQTT_TELEGRAF_PASSWORD=${var.mqtt_broker_telegraf_password}"
  ]
  ports {
    internal = 8883
    external = 8883
  }
  volumes {
    container_path = "/etc/telegraf/telegraf.conf"
    host_path      = abspath("config/telegraf.conf")
    read_only      = true
  }
}
# TODO test if env is loaded correctly and if volumes are mounted correctly