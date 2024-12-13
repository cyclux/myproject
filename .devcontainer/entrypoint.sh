#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

cd /workspace

# Check if docker is available and rootless
source .devcontainer/check_docker_rootless.sh

# Ensure PROJECT_NAME is set
if [ -z "$PROJECT_NAME" ]; then
  echo "PROJECT_NAME environment variable is not set."
  exit 1
fi

# Create a new environment using hatch
# TODO: Instead of - vs _ prevent the creation of a new environment if the project name is not in the correct format
# Only offer to create a new project if src directory doesn't exist
if [ ! -d "src" ]; then
  read -p "No hatch project found. Do you want to create a new hatch project for $PROJECT_NAME (using pyproject.toml)? (y/n): " CREATE_NEW_ENV

  if [[ "$CREATE_NEW_ENV" =~ ^[Yy]$ ]]; then
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Create new hatch project
    hatch new "$PROJECT_NAME"
    
    # Convert PROJECT_NAME underscores to hyphens to match hatch's convention
    HATCH_DIR_NAME=${PROJECT_NAME//_/-}
    
    # Move back to workspace
    cd /workspace
    
    # Move all files from the new project to workspace root, replacing existing files
    mv "$TEMP_DIR/$HATCH_DIR_NAME/"* .
    
    # Clean up
    rm -rf "$TEMP_DIR"
  fi
fi

hatch shell

# Execute the passed command (default is /bin/bash)
exec "$@"