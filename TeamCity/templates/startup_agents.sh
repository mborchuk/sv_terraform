#!/usr/bin/env bash
set -euo pipefail

# Avoid Terraform template by either using double dollar signs, or not using curly braces
readonly SCRIPT_NAME="$(basename "$0")"

# Send the log output from this script to startup-script.log, syslog, and the console
# Inspired by https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/startup-script.log|logger -t startup-script -s 2>/dev/console) 2>&1

function log {
  local readonly level="$1"
  local readonly message="$2"
  local readonly timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "$${timestamp} [$${level}] [$$SCRIPT_NAME] $${message}"
}

function log_info {
  local readonly message="$1"
  log "INFO" "$${message}"
}

function log_warn {
  local readonly message="$1"
  log "WARN" "$${message}"
}

function log_error {
  local readonly message="$1"
  log "ERROR" "$${message}"
}

function install_software() {
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

install_software
echo "${server_address} ${server_name}" >> /etc/hosts
mkdir -p /mnt/agentConf/
echo "auto_authorize=true" > /mnt/agentConf/buildAgent.properties
echo "autoAuthorize=true" >> /mnt/agentConf/buildAgent.properties
echo "autoManage=true" >> /mnt/agentConf/buildAgent.properties
echo "serverUrl=https://${server_address}" >> /mnt/agentConf/buildAgent.properties
docker run -d --restart always -u 0 -e SERVER_URL="https://${server_address}" -v /mnt/agentConf:/data/teamcity_agent/conf --privileged -e DOCKER_IN_DOCKER=start jetbrains/teamcity-agent