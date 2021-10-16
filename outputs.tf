output "container_id" {
  description = "ID of the Docker container"
  value       = docker_container.mosquitto.id
}

output "iamge_id" {
  description = "ID of the Docker image"
  value       = docker_image.mosquitto.id
}