#!/bin/bash

export IP_ADDRESS=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

apt-get update
# Install unzip and dnsmasq
apt-get install -y unzip dnsmasq docker.io git vim

## Setup consul
mkdir -p /var/lib/consul
mkdir -p /etc/consul.d

curl \
  --silent \
  --location \
  --output consul.zip \
  https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip
unzip consul.zip
mv consul /usr/local/bin/consul
rm consul.zip

cat > consul.service <<'EOF'
[Unit]
Description=consul
Documentation=https://consul.io/docs/

[Service]
ExecStart=/usr/local/bin/consul agent \
  -advertise=ADVERTISE_ADDR \
  -datacenter=${datacenter} \
  -bind=0.0.0.0 \
  -retry-join "provider=gce project_name=${project_id} tag_value=${retry_join_tag}" \
  -data-dir=/var/lib/consul \
  -config-dir=/etc/consul.d \
  -enable-script-checks

ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sed -i "s/ADVERTISE_ADDR/$IP_ADDRESS/" consul.service
mv consul.service /etc/systemd/system/consul.service
systemctl enable consul
systemctl start consul

# Configure dnsmasq
mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/10-consul <<'EOF'
server=/consul/127.0.0.1#8600
EOF

systemctl enable dnsmasq
systemctl start dnsmasq
# Force restart for adding consul dns
systemctl restart dnsmasq

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

cat > client.hcl <<EOF
addresses {
    rpc  = "ADVERTISE_ADDR"
    http = "ADVERTISE_ADDR"
}
advertise {
    http = "ADVERTISE_ADDR:4646"
    rpc  = "ADVERTISE_ADDR:4647"
}
datacenter = "${datacenter}"
region = "${region}"
data_dir  = "/var/lib/nomad"
log_level = "DEBUG"
client {
    enabled = true
    options {
        "driver.raw_exec.enable" = "1"
    }
}
EOF
# Replace ADVERTISE_ADDR with IP address
sed -i "s/ADVERTISE_ADDR/$IP_ADDRESS/" client.hcl
mv client.hcl /etc/nomad/client.hcl

cat > nomad.service <<'EOF'
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
[Service]
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

