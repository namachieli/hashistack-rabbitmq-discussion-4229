#!/bin/bash
# This script runs the first time the AMI is launched, and disables itself upon completion

# ------------------------------------------------------------------------------------------------
# SCRIPT VARIABLES
# ------------------------------------------------------------------------------------------------

SERVER_HOSTNAME_PREFIX="rts-"
CLIENT_HOSTNAME_PREFIX="rtc-"

# Don't change below here unless you know what you are doing

# No leading slash
IMDS_ENDPOINTS=(dynamic/instance-identity/document)

# The name of the tag that denotes this ami is for a consul server (bool)
CONSUL_SERVER_BOOL_TAG=consul_server
ENVIRONMENT_TAG=Environment

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

readonly EC2_IMDS_URL="http://169.254.169.254/latest/"
readonly EC2_DATA_DIR="/opt/ec2"
# readonly EC2_INSTANCE_METADATA_URL="http://169.254.169.254/latest/meta-data"
# readonly EC2_INSTANCE_DYNAMIC_DATA_URL="http://169.254.169.254/latest/dynamic"

IMDSv2_TOKEN=`curl --silent --show-error \
    -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

NOMAD_DRIVER_SCRIPT="/opt/provisioning/nomad_drivers.sh"

CHECK_FILE="/opt/provisioning/provision_complete"

CONSUL_SERVER_CNF="/etc/consul.d/server.hcl"
CONSUL_CLIENT_CNF="/etc/consul.d/client.hcl"
NOMAD_SERVER_CNF="/etc/nomad.d/server.hcl"
NOMAD_CLIENT_CNF="/etc/nomad.d/client.hcl"

CONSUL_SERVICE="/lib/systemd/system/consul.service"

ENCRYPTION=$(sudo cat /opt/enc)

# ------------------------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------------------------

# time stamps
function stamp() {
    date +%Y%m%dT%H%M%S%z
}

function load_ec2_instance_key() {
    jq --raw-output "$1" <${EC2_DATA_DIR}/*.json
}

function fetch_ec2_instance_data() {
    path=$1
    if [[ -z "$path" ]]; then
        echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): You must provide the resource path to fetch, including 'dynamic/' or 'meta-data/'"
        echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-categories.html"
    else
        curl -H "X-aws-ec2-metadata-token: $IMDSv2_TOKEN" \
            --silent --show-error --location \
            "${EC2_IMDS_URL}${path}"
    fi
}

# ------------------------------------------------------------------------------------------------
# PARSE INPUTS
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------
# VALIDATIONS
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------
# RUN
# ------------------------------------------------------------------------------------------------

echo "####"
echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Begin"
echo "####"

#
# Single run only
#

if test -f "$CHECK_FILE"; then
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): $CHECK_FILE exists, execution has ran previously. Skipping."
fi

#
# Get Instance Details
#

echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Fetching EC2 data for this instance into ${EC2_DATA_DIR}"
sudo mkdir ${EC2_DATA_DIR}
for endpoint in ${IMDS_ENDPOINTS[@]}; do
    data=$(fetch_ec2_instance_data ${endpoint})
    filename=$(sed 's`/`.`g' <<<"${endpoint}")

    # Write to file using HEREDOC
    sudo sh -c "cat <<EOF > ${EC2_DATA_DIR}/${filename}.json
${data}
EOF
"
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Data fetched for ${filename}"
done

#
# Load instance details
#
consul_server=$(fetch_ec2_instance_data "meta-data/tags/instance/${CONSUL_SERVER_BOOL_TAG}") && \
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): CONSUL Server: ${consul_server}"

env_tag=$(fetch_ec2_instance_data "meta-data/tags/instance/${ENVIRONMENT_TAG}") && \
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Environment loaded: ${env_tag}"

ec2_region=$(load_ec2_instance_key ".region") && \
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Region loaded: ${ec2_region}"

ec2_priv_ip=$(load_ec2_instance_key ".privateIp") && \
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): IPv4 addr loaded: ${ec2_priv_ip}"

ec2_az=$(load_ec2_instance_key ".availabilityZone") && \
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): AvailZone loaded: ${ec2_az}"

ec2_inst_id=$(load_ec2_instance_key ".instanceId") && \
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Instance ID loaded: ${ec2_inst_id}"

#
# Set Provisioning Mode
#
name_affix="${ec2_az}-${env_tag}-${ec2_inst_id:(-5)}"
if "$consul_server" = true; then
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Provisioning mode set to Server"
    SERVER=true
    new_hostname="${SERVER_HOSTNAME_PREFIX}${name_affix}"
else
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Provisioning mode set to Client"
    SERVER=false
    new_hostname="${CLIENT_HOSTNAME_PREFIX}${name_affix}"
fi

#
# Update node hostname
#
sudo sh -c "echo $new_hostname > /etc/hostname"
sudo sh -c "echo $ec2_priv_ip $new_hostname > /etc/hosts"
sudo hostname $new_hostname

#
# Create Configuration Files
#

echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Generating Configuration Files"

if [ "$SERVER" = true ]; then
#
# Consul Server Config
#

    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Configuring Consul for Server mode"

    # MVP: TODO: Actually secure Consul
    sudo touch ${CONSUL_SERVER_CNF}
    sudo sh -c "cat <<EOF >> ${CONSUL_SERVER_CNF}
# Full configuration options can be found at https://www.consul.io/docs/agent/options#configuration_files

datacenter  = \"${ec2_region}\"
data_dir    = \"/opt/consul/data\"
bind_addr   = \"${ec2_priv_ip}\"
client_addr = \"0.0.0.0\" # MVP:

ui_config {
  enabled = true
}

server           = true
bootstrap_expect = 3
encrypt          = \"${ENCRYPTION}\"
retry_join       = [\"provider=aws tag_key=${CONSUL_SERVER_BOOL_TAG} tag_value=true\"]
EOF
"
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Consul Server config created at ${CONSUL_SERVER_CNF}"

#
# Nomad Server Config
#

    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Configuring Nomad for Server mode"

    # MVP: TODO: Actually secure Nomad
    sudo touch ${NOMAD_SERVER_CNF}
    sudo sh -c "cat <<EOF >> ${NOMAD_SERVER_CNF}
# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

datacenter = \"${ec2_region}\"
data_dir   = \"/opt/nomad/data\"
bind_addr  = \"${ec2_priv_ip}\"

server {
  # license_path is required as of Nomad v1.1.1+
  #license_path    = \"/etc/nomad.d/nomad.hcl\"
  enabled          = true
  encrypt          = \"${ENCRYPTION}\"
  bootstrap_expect = 3
  # retry_join     = [] # Not needed when consul agent is on same local machine. Auto Discover.
}
# TODO: tls {} # https://learn.hashicorp.com/tutorials/nomad/security-enable-tls?in=nomad/transport-security
EOF
"

    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Nomad Server config created at ${NOMAD_SERVER_CNF}"

#
# ELSE (This is provisioning a CLIENT)
#
else

#
# Consul Client Config
#

    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Configuring Consul for Client Mode"

    sudo touch ${CONSUL_CLIENT_CNF}
    sudo sh -c "cat <<EOF >> ${CONSUL_CLIENT_CNF}

# Full configuration options can be found at https://www.consul.io/docs/agent/options#configuration_files

datacenter = \"${ec2_region}\"
data_dir   = \"/opt/consul/data\"
bind_addr  = \"${ec2_priv_ip}\"
client_addr = \"0.0.0.0\"

ui_config {
  enabled = true
}

server     = false
encrypt    = \"${ENCRYPTION}\"
retry_join = [\"provider=aws tag_key=${CONSUL_SERVER_BOOL_TAG} tag_value=true\"]

EOF
"
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Consul Client config created at ${CONSUL_CLIENT_CNF}"

#
# Nomad Client Config
#

    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Configuring Nomad for Client Mode"

    sudo touch ${NOMAD_CLIENT_CNF}
    sudo sh -c "cat <<EOF >> ${NOMAD_CLIENT_CNF}
# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

datacenter = \"${ec2_region}\"
data_dir   = \"/opt/consul/data\"
bind_addr  = \"${ec2_priv_ip}\"

client {
  enabled = true
  # server_join {
  #   retry_join = [] # Not needed when consul agent is on same local machine. Auto Discover.
  # }
}

# Enables 'Raw Exec' Driver. https://www.nomadproject.io/docs/drivers/raw_exec
plugin \"raw_exec\" {
  config {
    enabled = true
  }
}
# MVP: TODO: tls {} # https://learn.hashicorp.com/tutorials/nomad/security-enable-tls?in=nomad/transport-security

# Required to allow containers to mount /opt/<directory>
# https://www.nomadproject.io/docs/drivers/docker
plugin \"docker\" {
  config {
    volumes {
      enabled = true
    }
  }
}
EOF
"
    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Nomad Client config created at ${NOMAD_CLIENT_CNF}"

#
# Install Nomad Drivers (For CLIENT only)
#

    echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Installing Client drivers for Nomad"
    /bin/bash ${NOMAD_DRIVER_SCRIPT} -d
    # TODO: Add a check for this script. If it fails, take action that cuases this node to die and be rebuilt by ASG
#
# END IF
#
fi

#
# Temp fix for https://github.com/hashicorp/consul/issues/12107
# Remove fix once verified
#
FILE=/etc/consul.d/consul.env
if test -f "$FILE"; then
    echo "$FILE exists, skipping fix"
else
    # add a `-` `EnvironmentFile=` to tell systemd that the file doesn't have to exist
    sudo cp ${CONSUL_SERVICE} ${CONSUL_SERVICE}.dist
    sudo sed -i 's\EnvironmentFile=/\EnvironmentFile=-/\' ${CONSUL_SERVICE}
fi

echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Enabling & Starting Services"

sudo systemctl enable consul
sudo systemctl enable nomad
sudo systemctl start consul
sleep 15
sudo systemctl start nomad

#
# Create completion file to prevent additional executions.
#
echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Creating the CHECK_FILE at ${CHECK_FILE}"
touch ${CHECK_FILE}

echo "####"
echo "$(stamp) PROVISIONING SCRIPT (L${LINENO}): Complete"
echo "####"
