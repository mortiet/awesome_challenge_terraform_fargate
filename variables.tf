variable "name" {
  description = "deployment name"
  type        = string
}

variable "environment" {
  description = "deployment environment"
  type        = string
}

variable "cidr" {
  description = "vpc cidr block"
  type        = string
}

variable "private_subnet" {
  description = "private subnet"
  type        = string
}

variable "public_subnet" {
  description = "public subnet"
  type        = string
}

variable "availability_zone" {
  description = "availability zone"
  type        = string
}

variable "server_container_port" {
  description = "server port"
  type        = number
}

variable "server_container_image" {
  description = "container image used for server task"
  type        = string
}

variable "client_container_image" {
  description = "client image used for server task"
  type        = string
}

variable "AWS_REGION" {
  type = string
}
