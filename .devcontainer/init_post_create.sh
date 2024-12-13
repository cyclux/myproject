#!/bin/bash

# git clone git@gitlab.com:getml/all/monorepo.git ~/monorepo
# pip install -e ~/monorepo/src/python-api/

# Create .bash_profile in .devcontainer if it doesn't exist
mkdir -p /workspace/.devcontainer
# touch /workspace/.devcontainer/.bash_profile

# Set up history configuration
# cat > /workspace/.devcontainer/.bash_profile << 'EOF'
# History configuration
export HISTFILE=/workspace/.devcontainer/.bash_history
export HISTSIZE=10000
export HISTFILESIZE=20000
export PROMPT_COMMAND='history -a'

# Create history file if it doesn't exist
if [ ! -f "$HISTFILE" ]; then
    touch "$HISTFILE"
fi

# Ensure proper permissions
if [ -n "$USERNAME" ]; then
    sudo chown $USERNAME:$USERNAME "$HISTFILE"
    sudo chown $USERNAME:$USERNAME "$(dirname "$HISTFILE")"
fi


# Ensure the history file exists and has proper permissions
touch /workspace/.devcontainer/.bash_history
if [ -n "$USERNAME" ]; then
    sudo chown $USERNAME:$USERNAME /workspace/.devcontainer/.bash_history
fi

# Execute any additional post-attach commands
exec "$@"

