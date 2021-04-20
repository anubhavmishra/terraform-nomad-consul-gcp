# Terraform Nomad Consul on GCP

A set of scripts and Terraform configuration to create a Nomad
and Consul cluster on GCP.

## Usage

Terraform init

```bash
terraform init
```

Terraform plan

```bash
terraform plan -var="project_id=GCP_PROJECT_ID"
```

Terraform apply

```bash
terraform apply -var="project_id=GCP_PROJECT_ID"
```

SSH into Nomad and Consul server

```bash
$(terraform output nomad_consul_server_ssh)
```

*The above command creates SSH tunnel to allow access to Nomad
and Consul APIs and UIs.*

Open Nomad UI

```bash
open http://localhost:4646
```

Open Consul UI

```bash
open http://localhost:8500
```
