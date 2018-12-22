variable "region" {
  default = "us-west1"
}

variable "namespace" {
  default = "nomad-us"
}

variable "nomad_region" {
  default = "global"
}

variable "datacenter" {
  default = "dc1"
}

variable "consul_version" {
  default = "1.4.0"
}

variable "nomad_version" {
  default = "0.8.6"
}

variable "retry_join_tag" {
  default = "consul-server"
}

variable "username" {
  default = "demo"
}

variable "project_id" {
  description = "ID of the Google Cloud Platform project"
}
