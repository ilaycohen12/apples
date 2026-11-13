#!/bin/bash
# Runs ONCE as root on the server's first boot (EC2 user-data).
# Output log on the server: /var/log/cloud-init-output.log
# NOTE: Terraform fills in repo_url / repo_branch (templatefile).
set -euxo pipefail   # strict mode + print every command (x) for the log
export HOME=/root    # cloud-init runs without HOME; docker needs it

echo "==> 1. Add 2GB swap (t3.micro has only 1GB RAM)"
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab   # keep after reboot

echo "==> 2. Install git, curl"
apt-get update -y
apt-get install -y git curl

echo "==> 3. Install Docker + compose plugin (official install script)"
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker

echo "==> 4. Clone the repo"
git clone --branch ${repo_branch} ${repo_url} /opt/apples

echo "==> 5. Provision (the SAME script used locally and in CI)"
cd /opt/apples
./scripts/provision.sh

echo "==> Done: apples app is running"
