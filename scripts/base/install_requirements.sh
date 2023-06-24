#!/bin/bash

# Function to check if a package is installed on Debian-based systems
check_package_debian() {
    dpkg -s "$1" >/dev/null 2>&1
}

# Function to check if a package is installed on Red Hat-based systems
check_package_redhat() {
    rpm -q "$1" >/dev/null 2>&1
}

# Function to install a package on Debian-based systems
install_package_debian() {
    apt-get update >/dev/null 2>&1
    apt-get install -y "$1"
}

# Function to install a package on Red Hat-based systems
install_package_redhat() {
    yum install -y "$1"
}

# Function to check if a package is installed based on the Linux distribution
check_package() {
    if [ "$distro" == "Debian" ] || [ "$distro" == "Ubuntu" ]; then
        check_package_debian "$1"
    elif [ "$distro" == "CentOS" ] || [ "$distro" == "Rocky Linux" ]; then
        check_package_redhat "$1"
    fi
}

# Function to install a package based on the Linux distribution
install_package() {
    if [ "$distro" == "Debian" ] || [ "$distro" == "Ubuntu" ]; then
        install_package_debian "$1"
    elif [ "$distro" == "CentOS" ] || [ "$distro" == "Rocky Linux" ]; then
        install_package_redhat "$1"
    fi
}

# Check Linux distribution
distro=""
if [ -f "/etc/debian_version" ]; then
    distro="Debian"
elif [ -f "/etc/centos-release" ]; then
    distro="CentOS"
elif [ -f "/etc/rocky-release" ]; then
    distro="Rocky Linux"
elif [ -f "/etc/lsb-release" ]; then
    distro=$(grep "DISTRIB_ID" /etc/lsb-release | cut -d'=' -f2)
fi

# Check system architecture
architecture=$(uname -m)

# Check package installations
make_installed=0
gpp_installed=0
libreadline_installed=0

if check_package "make"; then
    make_installed=1
fi

if check_package "g++"; then
    gpp_installed=1
fi

if check_package "libreadline-dev"; then
    libreadline_installed=1
elif check_package "readline-devel"; then
    libreadline_installed=1
fi

# Print information
echo "Linux Distribution: $distro"
echo "Architecture: $architecture"
echo "---------------------------------------"
echo "Package Information:"
echo "make: $(if [ "$make_installed" -eq 1 ]; then echo "Installed"; else echo "Not Installed"; fi)"
echo "g++: $(if [ "$gpp_installed" -eq 1 ]; then echo "Installed"; else echo "Not Installed"; fi)"
echo "libreadline: $(if [ "$libreadline_installed" -eq 1 ]; then echo "Installed"; else echo "Not Installed"; fi)"

# Check if all packages are installed
if [ "$make_installed" -eq 1 ] && [ "$gpp_installed" -eq 1 ] && [ "$libreadline_installed" -eq 1 ]; then
    echo "All required packages are already installed."
    exit 0
fi

# Ask user if they want to install missing packages
read -p "Do you want to install missing packages? (y/n): " choice
if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
    if [ "$make_installed" -eq 0 ]; then
        install_package "make"
    fi
    if [ "$gpp_installed" -eq 0 ]; then
        install_package "g++"
    fi
    if [ "$libreadline_installed" -eq 0 ]; then
        if [ "$distro" == "Debian" ] || [ "$distro" == "Ubuntu" ]; then
            install_package "libreadline-dev"
        elif [ "$distro" == "CentOS" ] || [ "$distro" == "Rocky Linux" ]; then
            install_package "readline-devel"
        fi
    fi

    echo "Packages installed successfully!"
else
    echo "Packages were not installed."
fi

# Check package installations after possible installations
if check_package "make"; then
    make_installed=1
fi

if check_package "g++"; then
    gpp_installed=1
fi

if check_package "libreadline-dev"; then
    libreadline_installed=1
elif check_package "readline-devel"; then
    libreadline_installed=1
fi

# Print information again
echo "---------------------------------------"
echo "Updated Package Information:"
echo "make: $(if [ "$make_installed" -eq 1 ]; then echo "Installed"; else echo "Not Installed"; fi)"
echo "g++: $(if [ "$gpp_installed" -eq 1 ]; then echo "Installed"; else echo "Not Installed"; fi)"
echo "libreadline: $(if [ "$libreadline_installed" -eq 1 ]; then echo "Installed"; else echo "Not Installed"; fi)"
