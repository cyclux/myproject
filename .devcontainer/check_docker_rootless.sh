#!/bin/bash

# Check if docker is installed
if ! command -v docker &> /dev/null; then
  return 0
fi

echo "Verifying rootless Docker installation..."

docker_info=$(docker info --format '{{json .}}')

# Check if the Docker daemon is running by verifying that the "ID" field is not empty
docker_id=$(echo "$docker_info" | jq -r '.ID')

if [ -z "$docker_id" ]; then
  echo "==================================================================="
  echo "  Docker daemon not available! Please make sure docker is running  "
  echo "  and properly mounted into the container.                         "
  echo "==================================================================="
  exit 1
fi

# Check if "name=rootless" is in SecurityOptions
rootless=$(echo "$docker_info" | jq -r '.SecurityOptions | index("name=rootless")')

if [ "$rootless" != "null" ]; then
  is_rootless=true
else
  is_rootless=false
fi

if [ "$is_rootless" = false ]; then
  echo "====================================================================="
  echo "  Docker daemon is running as root! Please install rootless Docker.  "
  echo "  See: https://docs.docker.com/engine/security/rootless/             "
  echo "====================================================================="
  exit 1
fi
