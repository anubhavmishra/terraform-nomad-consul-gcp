#!/bin/bash

export IP_ADDRESS=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

apt-get update
# Install unzip and dnsmasq
apt-get install -y unzip dnsmasq docker.io git vim

# Install Envoy
wget https://github.com/nicholasjackson/cloud-pong/releases/download/v0.3.0/envoy -O /usr/local/bin/envoy
chmod +x /usr/local/bin/envoy

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

# Create the consul config
mkdir -p /etc/consul/config

cat << EOF > /etc/consul/config.hcl
data_dir = "/var/lib/consul"
log_level = "DEBUG"
datacenter = "${datacenter}"
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
ports {
  grpc = 8502
}
connect {
  enabled = true
}
enable_central_service_config = true
advertise_addr = "ADVERTISE_ADDR"
EOF

sed -i "s/ADVERTISE_ADDR/$IP_ADDRESS/" /etc/consul/config.hcl

cat > consul.service <<'EOF'
[Unit]
Description=consul
Documentation=https://consul.io/docs/

[Service]
ExecStart=/usr/local/bin/consul agent \
  -config-file=/etc/consul/config.hcl \
  -retry-join "provider=gce project_name=${project_id} tag_value=${retry_join_tag}" \
  -enable-script-checks

ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

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

# Configure CNI plugins
curl -L -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v0.8.3/cni-plugins-linux-amd64-v0.8.3.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

cat > 99-bridge-network-iptables.conf <<'EOF'
# Ensure the your Linux operating system distribution has been configured to allow container
# traffic through the bridge network to be routed via iptables. The below configuration preserves the settings
# Reference: https://www.nomadproject.io/guides/integrations/consul-connect/index.html#cni-plugins
net.bridge.bridge-nf-call-arptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
EOF
# Copy the sysctl.d configuration file
mv 99-bridge-network-iptables.conf /etc/sysctl.d/99-bridge-network-iptables.conf

# Enable and start nomad service
systemctl enable nomad
systemctl start nomad

