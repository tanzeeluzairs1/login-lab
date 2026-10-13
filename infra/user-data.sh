#!/bin/bash
set -euo pipefail

exec > >(tee -a /var/log/login-lab-bootstrap.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

# Update Linux and install repository prerequisites.
apt-get update
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg

# Configure Docker's package repository.
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Configure NodeSource's Node.js 24 repository.
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  -o /tmp/nodesource.asc

gpg --batch --yes --dearmor \
  -o /etc/apt/keyrings/nodesource.gpg /tmp/nodesource.asc

chmod a+r /etc/apt/keyrings/nodesource.gpg
rm /tmp/nodesource.asc

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" \
  > /etc/apt/sources.list.d/nodesource.list

# Install Docker, Compose, and Node.js.
apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \
  nodejs

systemctl enable --now docker

docker --version
docker compose version
node --version
npm --version

touch /var/lib/login-lab-bootstrap.done
echo "Login lab bootstrap completed successfully."