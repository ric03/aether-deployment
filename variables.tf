variable "keep_images_locally" {
  type    = bool
  default = true
}

variable "influxdb_access_token" {
  type      = string
  sensitive = true
}

variable "mqtt_broker_telegraf_password" {
  type      = string
  sensitive = true
}

variable "influxdb_password" {
  type      = string
  sensitive = true
}

variable "grafana_password" {
  type      = string
  sensitive = true
}
