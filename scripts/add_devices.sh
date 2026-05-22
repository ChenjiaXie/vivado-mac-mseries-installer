#!/bin/zsh

# Add devices to an existing Vivado installation inside the Docker container.
#
# Usage:
#   ./scripts/add_devices.sh [device_module_name]
#
# Examples:
#   ./scripts/add_devices.sh xcv80           # Add Versal Premium (Alveo V80)
#   ./scripts/add_devices.sh xcve2302        # Add Versal AI Edge
#   ./scripts/add_devices.sh xcvm1102        # Add Versal Prime
#
# Without arguments, it shows all available devices.
#
# This uses the installed xsetup at .xinstall/ to perform an incremental
# "Add" operation — no need to reinstall the entire tool.

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

# Check Docker is running
start_docker

# Check if container exists or if we need to use docker run
container_running=false
if [[ $(docker ps) == *vivado_container* ]]; then
    container_running=true
fi

# Path inside container
XILINX_DIR="/home/user/Xilinx"
XINSTALL_DIR="$XILINX_DIR/.xinstall"

# Detect installed version
version_dir=$(ls "$script_dir/../Xilinx/.xinstall/" 2>/dev/null | grep -E "^[0-9]" | head -1)
if [ -z "$version_dir" ]; then
    f_echo "Error: No Vivado installation found. Run setup.sh first."
    exit 1
fi
f_echo "Detected installed version: $version_dir"

XSETUP="$XINSTALL_DIR/$version_dir/xsetup"

# If no argument given, list available devices
if [ -z "$1" ]; then
    f_echo "Querying available devices... (this takes ~30s)"
    f_echo ""

    # Generate a config to see all available modules
    docker run --rm --mount type=bind,source="$script_dir/..",target="/home/user" \
        --platform linux/amd64 x64-linux \
        bash -c "HOME=/home/user /home/user/installer/xsetup -b ConfigGen -e 'Vivado ML Standard' -p Vivado -l /home/user/Xilinx 2>/dev/null; cat /home/user/.Xilinx/install_config.txt 2>/dev/null" \
        | grep "^Modules=" | sed 's/Modules=//' | tr ',' '\n' | sort

    f_echo ""
    f_echo "Usage: $0 <device_name>"
    f_echo "Example: $0 xcv80"
    exit 0
fi

DEVICE="$1"
f_echo "Adding device '$DEVICE' to Vivado $version_dir..."

# Create a temporary config file for the Add operation
ADD_CONFIG="/tmp/add_device_config.txt"
cat > "$script_dir/../.add_device_config.txt" << EOF
#### Vivado ML Standard Install Configuration ####
#### Add device: $DEVICE ####
Edition=Vivado ML Standard

Product=Vivado

Destination=/home/user/Xilinx

Modules=$DEVICE:1

InstallOptions=

CreateProgramGroupShortcuts=0
ProgramGroupFolder=AMD Adaptive SoC and FPGA Tools
CreateShortcutsForAllUsers=0
CreateDesktopShortcuts=0
CreateFileAssociation=0
EOF

f_echo "Running incremental device install inside Docker..."
f_echo "This may take 5-15 minutes depending on device size."
f_echo ""

# Use the INSTALLED xsetup (.xinstall/) with -b Add
# This is the correct way — the offline installer's xsetup rejects Add
# when it detects an existing installation, but the .xinstall one works.
docker run --rm --mount type=bind,source="$script_dir/..",target="/home/user" \
    --platform linux/amd64 x64-linux \
    bash -c "$XSETUP -b Add -c /home/user/.add_device_config.txt -a XilinxEULA,3rdPartyEULA 2>&1" \
    | grep -v "^$" | while IFS= read -r line; do
        # Show progress without flooding the terminal with spinner chars
        if [[ "$line" == *"completed"* ]]; then
            # Extract percentage
            pct=$(echo "$line" | grep -oE '[0-9]+%' | tail -1)
            if [ -n "$pct" ]; then
                printf "\r  Installing... %s" "$pct"
            fi
        elif [[ "$line" == *"INFO"* || "$line" == *"ERROR"* || "$line" == *"WARNING"* ]]; then
            echo ""
            echo "  $line"
        fi
    done

echo ""

# Cleanup temp config
rm -f "$script_dir/../.add_device_config.txt"

# Verify installation
f_echo "Verifying device availability..."
docker run --rm --mount type=bind,source="$script_dir/..",target="/home/user" \
    --platform linux/amd64 x64-linux \
    bash -c "source /home/user/Xilinx/$version_dir/Vivado/settings64.sh 2>/dev/null && vivado -mode tcl -nojournal -nolog <<EOF
set parts [get_parts ${DEVICE}*]
if {[llength \\\$parts] > 0} {
    puts \"SUCCESS: Found [llength \\\$parts] part(s) for $DEVICE\"
    foreach p \\\$parts { puts \"  \\\$p\" }
} else {
    puts \"WARNING: No parts found for $DEVICE after installation\"
}
exit
EOF" 2>&1 | grep -E "^SUCCESS|^WARNING|^  "

f_echo ""
f_echo "Done! Device '$DEVICE' has been added to your Vivado installation."
f_echo "Restart any running Vivado sessions to see the new device."
