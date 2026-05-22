#!/bin/bash

# This runs the Vivado installer in batch mode.
script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_linux

install_bin_path=$(tr -d "\n\r\t " < "/home/user/scripts/install_bin")
vivado_version=$(tr -d "\n\r\t " < "/home/user/scripts/install_version")

# Handle Extraction
if [[ "$install_bin_path" == *.tar ]]; then
    f_echo "Detected offline installer (.tar). Extracting... This will take a while."
    mkdir -p /home/user/installer
    tar -xf "$install_bin_path" -C /home/user/installer --strip-components=1
    f_echo "Extraction complete."
elif [[ "$install_bin_path" == *.bin ]]; then
    f_echo "Detected web installer (.bin). Extracting..."
    eval "$install_bin_path --target /home/user/installer --noexec"
    
    # Get AuthToken only for Web Installer
    f_echo "Log into your Xilinx account to download the necessary files."
    while ! /home/user/installer/xsetup -b AuthTokenGen
    do
        f_echo "Your account information seems to be wrong. Please try logging in again."
        sleep 1
    done
    f_echo "You successfully logged into your account."
else
    f_echo "Error: Unknown installer format. Please use .tar or .bin"
    exit 1
fi

# Run installer
f_echo "The silent installation will begin now."
eula_args="XilinxEULA,3rdPartyEULA"

if [ "$vivado_version" = "202110" ]; then
    eula_args="${eula_args},WebTalkTerms"
fi

if /home/user/installer/xsetup -c "/home/user/scripts/install_configs/${vivado_version}.txt" -b Install -a "${eula_args}"
then
    f_echo "Vivado was successfully installed."
    f_echo "Run start_container.sh to launch it with GUI, or use docker exec for CLI."
else
    f_echo "An error occurred during installation. Please check install_vivado.log or run cleanup.sh and try again."
    exit 1
fi