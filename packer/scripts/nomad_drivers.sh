#!/bin/bash
# This script handles the installation of requirements to enable Nomad Drivers
# See https://www.nomadproject.io/docs/drivers

# ------------------------------------------------------------------------------------------------
# SCRIPT VARIABLES
# ------------------------------------------------------------------------------------------------

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

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

# Parse flags into variables
while getopts d flag
do
    case $flag in
        d)
            # Install Docker
            export DOCKER=docker-ce
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

# Check that there are inputs
if [ -z "$1" ]
    then
    echo "You need some inputs for this script. Look at the source."
    exit 0;
fi

# ------------------------------------------------------------------------------------------------
# RUN
# ------------------------------------------------------------------------------------------------

echo "####"
echo "$(stamp) NOMAD DRIVER INSTALL (L${LINENO}): Begin"
echo "####"

sleep 30 # Race condition with apt

# Set up install requirements for Docker
if [[ -n "$DOCKER" ]]; then

    echo "$(stamp) NOMAD DRIVER INSTALL (L${LINENO}): Preparing Docker for Installation"

    # Purge existing
    sudo apt-get -qq -y purge "docker*" > /dev/null
    sudo apt-get -qq -y autoremove > /dev/null

    # Add proper Repository
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update and Install
    sudo apt-get -qq -y update > /dev/null

    DOCKER_CANDIDATE=$(sudo apt-cache policy $DOCKER | grep "^  Candidate")

    echo "$(stamp) NOMAD DRIVER INSTALL (L${LINENO}): Installing Docker - $DOCKER_CANDIDATE"

    sudo apt-get install -y $DOCKER > ./docker_install.log

    check_installed=$(apt-cache policy $DOCKER | grep "Installed: (none)")
    if [[ -n "${check_installed}" ]]; then
        echo "$(stamp) NOMAD DRIVER INSTALL (L${LINENO}): Failed to install Docker (see log at ./). Exiting..."
        exit 1
    fi

    echo "$(stamp) NOMAD DRIVER INSTALL (L${LINENO}): Successfully Installed Docker"
fi

echo "####"
echo "$(stamp) NOMAD DRIVER INSTALL (L${LINENO}): Complete"
echo "####"
