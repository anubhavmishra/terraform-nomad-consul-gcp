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