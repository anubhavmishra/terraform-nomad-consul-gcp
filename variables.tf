variable "region" {
  default = "asia-south1"
}

variable "namespace" {
  default = "nomad-asia-south"
}

variable "nomad_region" {
  default = "global"
}

variable "datacenter" {
  default = "dc1"
}

variable "consul_version" {
  default = "1.6.2"
}

variable "nomad_version" {
  default = "0.10.2"
}

variable "nomad_client_tags" {
  default = ["instance", "nomad-client"]
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
