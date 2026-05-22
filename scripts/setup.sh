#!/bin/zsh

# Initial setup on host (macOS) side
script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"

# Make sure that the script is run in macOS and not the Docker container
validate_macos

if [[ "$current_user" == "root" ]]; then
	f_echo "Do not execute this script as root."
	exit 1
fi

if [ -d "$script_dir/../Xilinx" ]; then
	f_echo "A previous installation was found. To reinstall, remove the Xilinx folder."
	exit 1
fi

validate_internet

f_echo "Advancing with the setup..."

# Check if the Mac is Intel or Apple Silicon
if [[ "$(uname -m)" == "x86_64" ]]; then
	f_echo "Mac is Intel-based. Rosetta installation is not required."
else
	if arch -arch x86_64 uname -m > /dev/null 2>&1; then
		f_echo "Rosetta is already installed."
	else
		f_echo "Rosetta is not installed."
		f_echo "Proceeding with Rosetta installation..."
		if ! softwareupdate --install-rosetta --agree-to-license; then
			f_echo "Error installing Rosetta."
			exit 1
		fi
	fi
fi

# Auto-detect installer
installer_file=$(ls "$script_dir"/../*.tar "$script_dir"/../*.bin 2>/dev/null | head -n 1)
if [ -z "$installer_file" ]; then
	f_echo "Error: No Vivado installer (.tar offline installer or .bin web installer) found in the folder!"
	f_echo "Please put the installer file in the root directory and run again."
	exit 1
fi

installer_filename=$(basename "$installer_file")
installation_binary="/home/user/$installer_filename"
f_echo "Detected installer: $installer_filename"

# Try to detect version from filename to support offline tar
if [[ "$installer_filename" == *"2025.2.1"* ]]; then
	vivado_version="202521"
elif [[ "$installer_filename" == *"2025.2"* ]]; then
	vivado_version="202520"
elif [[ "$installer_filename" == *"2025.1"* ]]; then
	vivado_version="202510"
elif [[ "$installer_filename" == *"2024.2"* ]]; then
	vivado_version="202420"
elif [[ "$installer_filename" == *"2024.1"* ]]; then
	vivado_version="202410"
else
	# Fallback to MD5 hash detection for older .bin installers
	file_hash=$(md5 -q "$installer_file")
	set_vivado_version_from_hash "$file_hash"
	if [ "$?" -ne 0 ]; then
		f_echo "File corrupted or version not supported automatically. Please check hashes.sh."
		exit 1
	fi
fi
f_echo "Using Vivado Version configuration: $vivado_version"

# write file path and version to be accessed inside Docker
echo -n "$installation_binary" > "$script_dir/install_bin"
echo -n "$vivado_version" > "$script_dir/install_version"

# Make the user own the whole folder
if ! chown -R $current_user "$script_dir/.."; then
	f_echo "Higher privileges are required to make the folder owned by the user."
	if ! sudo chown -R $current_user "$script_dir/.."; then
		f_echo "Error setting $current_user as owner of this folder."
		exit 1
	fi
fi

# Make the scripts executable
if xattr -p com.apple.quarantine "$script_dir/xvcd/bin/xvcd" &>/dev/null; then
	if ! xattr -d com.apple.quarantine "$script_dir/xvcd/bin/xvcd"; then
		f_echo "You need to remove the quarantine attribute from $script_dir/xvcd/bin/xvcd manually."
		wait_for_user_input
	fi
fi

# Only chmod scripts, do not chmod the installer (prevents tar errors)
if ! chmod +x "$script_dir"/*.sh "$script_dir/xvcd/bin/xvcd"; then
	f_echo "Error making the scripts executable."
	exit 1
fi

start_docker
eval "$script_dir/configure_docker.sh"

if ! eval "$script_dir/gen_image.sh"; then
	exit 1
fi

# Set default resolution
resolution="1920x1080"
echo "$resolution" > "$script_dir/vnc_resolution"

mkdir -p "$script_dir/../.config/autostart"
cp "$script_dir/de_start.desktop" "$script_dir/../.config/autostart/de_start.desktop"
mkdir -p "$script_dir/../Desktop"

f_echo "Now, the container is started (only terminal, no GUI) and the actual installation process begins."
docker run --init --rm --name vivado_container --mount type=bind,source="$script_dir/..",target="/home/user" -p 127.0.0.1:5901:5901 --platform linux/amd64 x64-linux sudo -H -u user bash /home/user/scripts/install_vivado.sh
