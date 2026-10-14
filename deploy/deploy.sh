#!/usr/bin/env bash
set -euo pipefail

# Run as root through SSM or sudo.
if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script with sudo."
  exit 1
fi

export AWS_REGION="ap-south-1"
export AWS_DEFAULT_REGION="$AWS_REGION"
export REGISTRY="425034746374.dkr.ecr.ap-south-1.amazonaws.com"
export IMAGE_TAG="${1:?Provide the image tag as the first argument}"

if [[ ! "$IMAGE_TAG" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,127}$ ]]; then
  echo "Invalid image tag."
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/compose.ec2.yaml"

test -f "$COMPOSE_FILE"
command -v aws >/dev/null
docker compose version >/dev/null

# Prevent overlapping deployments on this instance.
exec 9>/var/lock/login-lab-deploy.lock
flock -w 300 9

# Read the current public IP using EC2 IMDSv2.
METADATA_TOKEN="$(curl --noproxy '*' -fsS --max-time 10 \
  -X PUT \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60" \
  http://169.254.169.254/latest/api/token)"

PUBLIC_IP="$(curl --noproxy '*' -fsS --max-time 10 \
  -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)"

test -n "$PUBLIC_IP"
export APP_ORIGIN="http://$PUBLIC_IP:3000"

# Retrieve the password without printing it.
DEMO_PASSWORD="$(aws ssm get-parameter \
  --name /login-lab/demo-password \
  --with-decryption \
  --region "$AWS_REGION" \
  --query 'Parameter.Value' \
  --output text)"

test -n "$DEMO_PASSWORD"
export DEMO_PASSWORD
trap 'unset DEMO_PASSWORD METADATA_TOKEN' EXIT

# Authenticate Docker using the EC2 instance role.
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login \
      --username AWS \
      --password-stdin "$REGISTRY"

# Supply variables from this script instead of a local .env file.
COMPOSE=(
  docker compose
  --env-file /dev/null
  -p login-lab
  -f "$COMPOSE_FILE"
)

echo "Pulling application images tagged $IMAGE_TAG"
"${COMPOSE[@]}" pull

echo "Starting application"
"${COMPOSE[@]}" up -d --wait --wait-timeout 180

# Check the frontend-to-backend connection.
curl -fsS \
  --retry 10 \
  --retry-delay 3 \
  --retry-connrefused \
  --max-time 10 \
  http://127.0.0.1:3000/api/health

echo
"${COMPOSE[@]}" ps
echo "Deployment completed: $APP_ORIGIN"