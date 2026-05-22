# Vivado on Apple Silicon Mac (M1/M2/M3/M4/M5)

[中文说明](README_zh-CN.md)

This is a refined, automated tool for installing [Vivado™](https://www.xilinx.com/support/download/index.html) on Arm®-based Apple Silicon Macs (including the latest M4 and M5 chips) in a Rosetta-enabled virtual machine. 

This repository is a clean, enhanced fork based on the original work by [ichi4096/vivado-on-silicon-mac](https://github.com/ichi4096/vivado-on-silicon-mac).

## Features & Improvements
* **Apple Silicon Support**: Compatible with M1, M2, M3, M4, and M5 chips.
* **Offline Installer Support**: Automatically detects and extracts `.tar` offline installers (Single File Download), bypassing terminal authentication and network downloads.
* **Automated Installation**: Removed interactive prompts (e.g., EULA agreement, resolution prompts) for a silent install process.
* **Updated Component Configurations**: Removed deprecated components (e.g., Vitis Model Composer) for compatibility with the 2025.x installer.

## Supported Versions
* 2025.2, 2025.1
* 2024.2, 2024.1
* 2023.2, 2023.1
* 2022.2, 2021.1

## How to Install

### 1. Preparations
1. Install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/). **Crucial:** You must choose the "Apple Chip" version.
2. In Docker Settings -> General / Features in development, **ENABLE "Use Rosetta for x86/amd64 emulation on Apple Silicon"**.
3. In Docker Settings -> Resources, allocate at least **8GB RAM** (12GB+ recommended).
4. Download the Vivado Installer from AMD (Either the Linux Self-Extracting `.bin` Web Installer OR the `.tar` Offline Single File Download).

### 2. Installation
1. Clone or download this repository.
2. Place the downloaded Vivado installer (`.bin` or `.tar`) directly into the root folder of this repository.
3. Open a terminal, navigate to the folder, and run:
   ```bash
   caffeinate -dim zsh ./scripts/setup.sh
   ```
4. If using a `.tar` offline installer, go grab a coffee. If using a `.bin` web installer, the terminal will prompt you to enter your AMD credentials once before proceeding.

### 3. Usage (GUI Mode)
Run the following script to start the container and automatically open macOS Screen Sharing:
```bash
./scripts/start_container.sh
```
*Note: Your Mac folder is mounted to `/home/user` inside the container. Keep your project files here to ensure they persist between reboots.*

### 4. Usage (CLI / Headless Mode)
If you only need to run Vivado in batch or Tcl mode without a desktop environment:
```bash
docker start vivado_container
docker exec -it vivado_container bash
# Inside container:
source /home/user/Xilinx/Vivado/2025.2/settings64.sh
vivado -mode tcl
```

## Credits & License
* **Original Author**: [ichi4096](https://github.com/ichi4096/vivado-on-silicon-mac)
* The repository's contents are licensed under the Creative Commons Zero v1.0 Universal license.
* Apple, Mac, Rosetta, Docker, AMD, Xilinx, and Vivado are trademarks of their respective owners.