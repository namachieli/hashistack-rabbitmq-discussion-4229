#!/bin/bash
# This script handles the Installation of binaries and basic instance config for AMI Packing

# ------------------------------------------------------------------------------------------------
# SCRIPT VARIABLES
# ------------------------------------------------------------------------------------------------

export dummy_int_name="consul0"
export dummy_int_ipv4_cidr="169.254.1.53/32"

export default_dns_lo_ipv4="127.0.0.53"
export default_dns_port=53
export CONSUL_DNS_PORT=8600


# Don't change these unless you know what you are doing
export dependency_list="jq net-tools dnsutils ldnsutils"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

export PROVISIONING_SCRIPT="/opt/provisioning/nomad_self_provision.sh"
export PROVISIONING_LOG="/opt/provisioning/nomad_self_provision.log"



# ------------------------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------------------------

# time stamps
function stamp()
{
    date +%Y%m%dT%H%M%S%z
}

# ------------------------------------------------------------------------------------------------
# PARSE INPUTS
# ------------------------------------------------------------------------------------------------

while getopts e: flag
do
    case $flag in
        e)
            # Gossip Encryption Key
            export ENCRYPTION=$OPTARG
            ;;
        ?)
            #Didn't find that flag
            echo "ERROR: Unrecognized option, see source for details"
            exit 0;;
    esac
done

# ------------------------------------------------------------------------------------------------
# VALIDATIONS
# ------------------------------------------------------------------------------------------------

# Encryption
# TODO: Add a validation that the key is base64 encoded, if it isn't use the input and encode it.
# Probably a simple regex check should do it?
if [[ -z "$ENCRYPTION" ]]; then
    echo "####"
    echo "$(stamp) INSTALL SCRIPT (L${LINENO}): ERROR: No value passed for '-e'"
    echo "$(stamp) You must pass a string with the value of a base64 encoded encryption PSK"
    echo "$(stamp) Exiting..."
    echo "####"
    exit 1
fi

# ------------------------------------------------------------------------------------------------
# RUN
# ------------------------------------------------------------------------------------------------

echo "####"
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Begin"
echo "####"

# Seems to be a race condition with other packages installing as part of the AMI deploy.
# Adding a sleep to see if that helps...
# TODO: Better approach is a programmatic check for no lock
sleep 30

sudo sh -c "cat <<EOF >> /opt/enc
$ENCRYPTION
EOF
"
sudo chmod 660 /opt/enc

#
# Update and Install Dependencies
#
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Running Apt Update"
sudo apt-get -qq -y update > /dev/null

echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Running Apt install (ignore debconf errors)"
sudo apt-get -qq install -y ${dependency_list} > /dev/null

# Check if dependencies were installed
check_installed=$(apt-cache policy ${dependency_list} | grep "Installed: (none)")
if [[ -n "${check_installed}" ]]; then
    echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Failed to install a system dependency. Exiting..."
    exit 1
fi

#
# Configure DNS: systemd-resolved & DNS Masquerade
#
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Configure DNS: systemd-resolved & DNS Masquerade"

echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Creating configuration files for 'dummy' interface (${dummy_int_name})"
export dummy_int_ipv4=$(echo $dummy_int_ipv4_cidr | cut -d/ -f 1) # ip without cidr

# Create dummy interface for DNS Masq using system-networkd
sudo sh -c "cat <<EOF >> /etc/systemd/network/${dummy_int_name}.netdev
[NetDev]
Name=${dummy_int_name}
Kind=dummy
EOF"

sudo sh -c "cat <<EOF >> /etc/systemd/network/${dummy_int_name}.network
[NetDev]
[Match]
Name=${dummy_int_name}

[Network]
Address=${dummy_int_ipv4_cidr}
EOF"

# Restart to pick up new int
sudo systemctl restart systemd-networkd && sleep 1

# Validate dummy int exists
#
consul0=$(ip addr show dev ${dummy_int_name} | grep "inet " | awk '{print $2}')
if [[ "${consul0}" != "${dummy_int_ipv4_cidr}" ]]; then
    echo "$(stamp) INSTALL SCRIPT (L${LINENO}): CRITICAL: Failed to create and bringup dummy interface: ${dummy_int_name} on IP: ${dummy_int_ipv4_cidr}"
    exit 1
else
    echo "$(stamp) INSTALL SCRIPT (L${LINENO}): 'Dummy' Interface (${dummy_int_name}) created successfully"
fi

# Create DNS Masq config files
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Create DNS Masq config files"

sudo mkdir -p /etc/dnsmasq.d

sudo sh -c "cat <<EOF >> /etc/dnsmasq.d/consul
server=/consul/${dummy_int_ipv4}#${CONSUL_DNS_PORT}
listen-address=${dummy_int_ipv4}
interface=${dummy_int_name}
EOF"

sudo sh -c "cat <<EOF >> /etc/dnsmasq.d/default
port=${default_dns_port}
server=${default_dns_lo_ipv4}
bind-interfaces
EOF"

# Start and check DNS Masq
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Install and check DNS Masq"

# sudo systemctl start dnsmasq
sudo apt-get -qq -y install dnsmasq > /dev/null

# Active: failed (Result: exit-code) since Tue 2022-02-22 22:24:47 UTC; 2s ago
# Active: active (running) since Tue 2022-02-22 22:59:45 UTC; 4min 31s ago
dnsmasq_check=$(sudo systemctl status dnsmasq | grep "Active:" | awk '{print $3}')

if [[ "${dnsmasq_check}" != "(running)" ]]; then
    echo "$(stamp) INSTALL SCRIPT (L${LINENO}): CRITICAL: DNSMASQ failed to start:"
    # Output some logs
    sudo journalctl -n 10 --no-pager -u dnsmasq
    exit 1
else
    echo "$(stamp) INSTALL SCRIPT (L${LINENO}): DNSMASQ started successfully"
fi

# Modify Primary DNS Server (systemd-resolved default_dns_lo_ipv4 -> dummy_int_ipv4)
sudo sed -i "s/nameserver ${default_dns_lo_ipv4}/nameserver ${dummy_int_ipv4}/" /etc/resolv.conf

# Add the domain 'node.consul' to resolv.conf
sudo sh -c "cat <<EOF >> /etc/resolv.conf
domain node.consul
EOF"

#
# Add Hashicorp Repo
#
echo "####"
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Adding Hashicorp Repository"
echo "####"

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get -qq -y update > /dev/null

#
# Install Consul
#
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Installing Consul  (ignore debconf errors)"

sudo apt-get -qq -y install consul > /dev/null

consul_installed=$(consul -v | grep "Consul")
if [[ -z "${consul_installed}" ]]; then
    echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Failed to install Consul. Exiting..."
    exit 1
fi

#Back up default config for posterity
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Backing up distro Consul Config"
sudo mv /etc/consul.d/consul.hcl /etc/consul.d/consul.hcl.dist

# Default service file points to the default config file, and wont work since we replace it.
# Comment out `ConditionFileNotEmpty=/etc/consul.d/consul.hcl` from /lib/systemd/system/consul.service
sudo sed -e '/ConditionFileNotEmpty/ s/^#*/#/' -i /lib/systemd/system/consul.service

#
# Install Nomad
#
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Installing Nomad (ignore debconf errors)"

sudo apt-get -qq -y install nomad > /dev/null

nomad_installed=$(nomad -v | grep "Nomad")
if [[ -z "${nomad_installed}" ]]; then
    echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Failed to install Nomad. Exiting..."
    exit 1
fi

# Back up default config for posterity
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Backing up distro Nomad Config"
sudo mv /etc/nomad.d/nomad.hcl /etc/nomad.d/nomad.hcl.dist

#
# Prepare for ASG Deployment
#

# Setup crontab to run provisioning on reboot
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Set provision script to run on first Boot (ignore error, fake news)"
(crontab -l ; echo "@reboot ${PROVISIONING_SCRIPT} >> ${PROVISIONING_LOG}") | crontab -

echo "####"
echo "$(stamp) INSTALL SCRIPT (L${LINENO}): Complete"
echo "####"
