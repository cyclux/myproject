#!/bin/bash

# Define the path to the pyproject.toml and .env files
TOML_FILE="pyproject.toml"
ENV_FILE=".devcontainer/.env"

# Create .env file and directory if they don't exist
# TODO: Check if mkdir makes sense
mkdir -p .devcontainer
touch "$ENV_FILE"

# Function to check and set tool installation
check_for_existing_container() {
    # Define the container name using the PROJECT_NAME environment variable
    CONTAINER_NAME="${PROJECT_NAME}_dev_container"

    # Check if a container with the same name already exists and remove it if it does
    if [ "$(docker ps -a -q -f name=${CONTAINER_NAME})" ]; then
        echo "Removing existing container with name ${CONTAINER_NAME}..."
        docker rm -f ${CONTAINER_NAME}
    fi
}

# If .env file exists: 
# - load all environment variables from the .env file
# - exit if SETUP_COMPLETE is true
if [ -f "$ENV_FILE" ]; then
    # Load all variables from the .env file
    set -a
    source "$ENV_FILE"
    set +a

    # Check if SETUP_COMPLETE is set to true
    if [ "$SETUP_COMPLETE" = "true" ]; then
        echo "Development container is already set up. Starting development container..."
        exit 0
    fi
fi

# Check if the pyproject.toml file exists
if [ ! -f "$TOML_FILE" ]; then
    echo "Error: $TOML_FILE not found. Please make sure the file exists in the root working directory."
    exit 1
fi

# Determine the project name from loaded environment variables or prompt the user
if [ -n "$PROJECT_NAME" ]; then
    echo "Using PROJECT_NAME from $ENV_FILE: $PROJECT_NAME"
else
    CURRENT_DIR_NAME=$(basename "$PWD")
    if [ "$CURRENT_DIR_NAME" != "devcontainer" ]; then
        read -p "Enter project name (or press Enter to use '$CURRENT_DIR_NAME'): " PROJECT_NAME
        PROJECT_NAME="${PROJECT_NAME:-$CURRENT_DIR_NAME}"
    else
        read -p "Please enter the project name: " PROJECT_NAME
    fi

    # Add or update PROJECT_NAME in .env file
    grep -q "PROJECT_NAME=" "$ENV_FILE" && sed -i "s/PROJECT_NAME=.*/PROJECT_NAME=$PROJECT_NAME/" "$ENV_FILE" || echo "PROJECT_NAME=$PROJECT_NAME" >> "$ENV_FILE"
fi

# Replace "devcontainer" with the value of PROJECT_NAME in pyproject.toml
sed -i "s/devcontainer/$PROJECT_NAME/g" "$TOML_FILE"

# Function to check and set tool installation
check_and_set_tool() {
    local TOOL_NAME=$1
    local ENV_VAR="INSTALL_$TOOL_NAME"
    
    if [ -n "${!ENV_VAR}" ]; then
        if [ "${!ENV_VAR}" = "true" ]; then
            echo "$TOOL_NAME is set to be installed according to $ENV_FILE."
        else
            echo "$TOOL_NAME will not be installed according to $ENV_FILE."
        fi
    else
        read -p "Install $TOOL_NAME? (y/n): " ANSWER
        if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
            echo "$ENV_VAR=true" >> "$ENV_FILE"
        else
            echo "$ENV_VAR=false" >> "$ENV_FILE"
        fi
    fi
}

echo "Checking which tools to install in your dev environment..."

TOOLS=("TERRAFORM" "GCLOUD" "HADOLINT" "DOCKER")

# Loop through each tool in the list and check/set installation
for TOOL in "${TOOLS[@]}"; do
    check_and_set_tool "$TOOL"
done

# Reload the updated .env file to ensure all variables are available in the current session
set -a
source "$ENV_FILE"
set +a

# Setup git repository
read -p "Do you want to set up a new repository? (y/n): " SETUP_NEW_REPO

if [[ "$SETUP_NEW_REPO" =~ ^[Yy]$ ]]; then
    read -p "Please enter the new remote repository URL: " NEW_REPO_URL

    echo "Removing existing Git history..."
    rm -rf .git

    echo "Reinitializing Git repository..."
    git init -b main

    git remote add origin "$NEW_REPO_URL"
    echo "New remote origin added: $NEW_REPO_URL"
    
    echo "Setting tracking information for main branch..."
    git branch --set-upstream-to=origin/main main

    echo "Pulling changes from the remote repository..."    
    git pull --rebase
fi

# Check INSTALL_DOCKER and set TARGET_STAGE, CONTAINER_HOME and CONTAINER_USER
if [ "$INSTALL_DOCKER" = "true" ]; then
    echo "Setting TARGET_STAGE to development_root"
    grep -q "TARGET_STAGE=" "$ENV_FILE" && sed -i "s/TARGET_STAGE=.*/TARGET_STAGE=development_root/" "$ENV_FILE" || echo "TARGET_STAGE=development_root" >> "$ENV_FILE"
    grep -q "CONTAINER_HOME=" "$ENV_FILE" && sed -i "s/CONTAINER_HOME=.*/CONTAINER_HOME=\/root/" "$ENV_FILE" || echo "CONTAINER_HOME=/root" >> "$ENV_FILE"
    grep -q "CONTAINER_USER=" "$ENV_FILE" && sed -i "s/CONTAINER_USER=.*/CONTAINER_USER=root" "$ENV_FILE" || echo "CONTAINER_USER=root" >> "$ENV_FILE"
else
    echo "Setting TARGET_STAGE to development"
    grep -q "TARGET_STAGE=" "$ENV_FILE" && sed -i "s/TARGET_STAGE=.*/TARGET_STAGE=development/" "$ENV_FILE" || echo "TARGET_STAGE=development" >> "$ENV_FILE"
    grep -q "CONTAINER_HOME=" "$ENV_FILE" && sed -i "s/CONTAINER_HOME=.*/CONTAINER_HOME=\/home\/vscode/" "$ENV_FILE" || echo "CONTAINER_HOME=/home/vscode" >> "$ENV_FILE"
    grep -q "CONTAINER_USER=" "$ENV_FILE" && sed -i "s/CONTAINER_USER=.*/CONTAINER_USER=vscode" "$ENV_FILE" || echo "CONTAINER_USER=vscode" >> "$ENV_FILE"
fi

# Mark setup as complete
grep -q "SETUP_COMPLETE=" "$ENV_FILE" && sed -i "s/SETUP_COMPLETE=.*/SETUP_COMPLETE=true/" "$ENV_FILE" || echo "SETUP_COMPLETE=true" >> "$ENV_FILE"

echo "Initial project setup complete."
check_for_existing_container
echo "Starting dev container..."
exit 0
