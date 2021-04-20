variable "region" {
  default = "us-west2"
}

variable "namespace" {
  default = "nomad-us-west-2"
}

variable "nomad_region" {
  default = "global"
}

variable "datacenter" {
  default = "dc1"
}

variable "consul_version" {
  default = "1.9.5"
}

variable "nomad_version" {
  default = "1.0.4"
}

variable "vault_version" {
  default = "1.7.0"
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
