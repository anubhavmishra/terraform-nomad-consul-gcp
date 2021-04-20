#!/bin/bash


export IP_ADDRESS=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

apt-get update
# Install unzip, git, and vim
apt-get install -y unzip git vim


# Download and install Vault 
curl \
  --silent \
  --location \
  --output vault.zip \
  https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip
unzip vault.zip
mv vault /usr/local/bin/vault
rm vault.zip

mkdir -p /etc/vault

cat > server.hcl <<'EOF'
ui = true
EOF

mv server.hcl /etc/vault/server.hcl

cat > vault.service <<'EOF'
[Unit]
Description=vault
Documentation=https://vaultproject.io/docs/

[Service]
Environment="VAULT_DEV_ROOT_TOKEN_ID=root"
ExecStart=/usr/local/bin/vault server -dev -dev-listen-address="0.0.0.0:8200" -config="/etc/vault/server.hcl"

ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Create vault health check for consul

cat > vault.hcl <<'EOF'
services {
  id = "vault"
  name = "vault"
  address = ""
  port = 8200
  checks = [
    {
      name = "vault-http"
      http = "http://127.0.0.1:8200/v1/sys/health"
      interval = "5s"
      timeout = "20s"
    }
  ]
}
EOF

mv vault.hcl /etc/consul

mv vault.service /etc/systemd/system/vault.service
systemctl enable vault
systemctl start vault
systemctl reload consul