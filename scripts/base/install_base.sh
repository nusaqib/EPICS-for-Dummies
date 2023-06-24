#!/bin/bash

# Check if either 'epics-base' or 'base' directory already exists
if [ -d "epics-base" ] || [ -d "base" ]; then
    echo "EPICS Base or base directory already exists. Proceeding to the next step..."
else
    # Clone EPICS Base from GitHub
    git clone --recursive https://github.com/epics-base/epics-base.git
fi

# Change to the cloned directory
cd epics-base || cd base

# Navigate to the 'configure' directory
cd configure

# Ask the user for the installation path
read -p "Enter the installation path for EPICS Base (leave empty to skip): " install_path

# If installation path is provided, update or create CONFIG_SITE.local file
if [[ -n "$install_path" ]]; then
    if [ -e "CONFIG_SITE.local" ]; then
        sed -i "s/INSTALL_LOCATION=.*/INSTALL_LOCATION=$install_path/" CONFIG_SITE.local
    else
        echo "INSTALL_LOCATION=$install_path" > CONFIG_SITE.local
    fi
fi

# Change back to the 'epics-base' directory
cd ..

# Run make
make
