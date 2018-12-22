#!/bin/bash

export IP_ADDRESS=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

apt-get update
# Install unzip and dnsmasq
apt-get install -y unzip dnsmasq

## Setup consul
mkdir -p /var/lib/consul

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
  -bootstrap-expect 3 \
  -retry-join "provider=gce project_name=${project_id} tag_value=${retry_join_tag}" \
  -client=0.0.0.0 \
  -data-dir=/var/lib/consul \
  -server \
  -ui

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

