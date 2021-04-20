#!/bin/bash

export IP_ADDRESS=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

apt-get update
# Install unzip and dnsmasq
apt-get install -y unzip git vim


# Download and install Nomad 
curl \
  --silent \
  --location \
  --output nomad.zip \
  https://releases.hashicorp.com/nomad/${nomad_version}/nomad_${nomad_version}_linux_amd64.zip
unzip nomad.zip
mv nomad /usr/local/bin/nomad
rm nomad.zip

mkdir -p /var/lib/nomad
mkdir -p /etc/nomad

cat > server.hcl <<EOF
addresses {
    rpc  = "ADVERTISE_ADDR"
    serf = "ADVERTISE_ADDR"
}

advertise {
    http = "ADVERTISE_ADDR:4646"
    rpc  = "ADVERTISE_ADDR:4647"
    serf = "ADVERTISE_ADDR:4648"
}

bind_addr = "0.0.0.0"
datacenter = "${datacenter}"
region = "${region}"
data_dir  = "/var/lib/nomad"
log_level = "DEBUG"

server {
    enabled = true
    bootstrap_expect = 3
}

vault {
  enabled = true
  address = "http://vault.service.consul:8200"
}
EOF
# Replace ADVERTISE_ADDR with IP address
sed -i "s/ADVERTISE_ADDR/$IP_ADDRESS/" server.hcl
mv server.hcl /etc/nomad/server.hcl

# Create systemd file
cat > nomad.service <<'EOF'
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/

[Service]
Environment="VAULT_TOKEN=root"
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
# Install systemd file
mv nomad.service /etc/systemd/system/nomad.service

# Enable and start nomad service
systemctl enable nomad
systemctl start nomad


