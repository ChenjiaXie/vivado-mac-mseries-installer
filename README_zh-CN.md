# Vivado on Mac M-Series (Auto-Installer)

这是一个经过深度优化和自动化重构的工具，用于在基于 Arm 架构的 Apple Silicon Mac（全面支持最新的 **M4** 和 **M5** 芯片）上，借助 Rosetta 2 翻译层和 Docker 虚拟化技术安装和运行 [Vivado™](https://www.xilinx.com/support/download/index.html)。

本项目是基于 [ichi4096/vivado-on-silicon-mac](https://github.com/ichi4096/vivado-on-silicon-mac) 开源项目的深度定制分支。

[English Version](README.md)

## 核心特性与优化
* **支持 Apple Silicon 芯片**：兼容 M1, M2, M3, M4 以及 M5 芯片。
* **支持离线安装包 (.tar)**：支持自动识别并提取 `.tar` 离线安装包（Single File Download），无需通过终端进行 AMD 账号联网鉴权。
* **自动化静默安装**：简化了交互流程（去除了手动同意 EULA、设置分辨率等步骤），通过脚本执行后台安装。
* **更新组件配置**：移除了 2025.x 等版本安装包中已弃用的组件（如 Vitis Model Composer），修复了解析报错问题。

## 📦 支持的 Vivado 版本
* 2025.2, 2025.1
* 2024.2, 2024.1
* 2023.2, 2023.1
* 2022.2, 2021.1

## 🛠️ 安装指南

### 1. 准备工作
1. 安装 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)。**注意：** 下载时务必选择 "Apple Chip"（苹果芯片）版本。
2. 打开 Docker 设置 -> `General`（或 `Features in development`），**务必勾选开启 "Use Rosetta for x86/amd64 emulation on Apple Silicon"**。
3. 打开 Docker 设置 -> `Resources`，将 Memory（内存）至少分配 **8GB**（强烈推荐 12GB 或更高）。
4. 前往 AMD 官网下载 Vivado 安装包（可以是 `.bin` 格式的在线安装器，也可以是上百G的 `.tar` 离线完整安装包）。

### 2. 开始安装
1. 克隆或下载本仓库到你的 Mac。
2. 将下载好的 Vivado 安装包（`.bin` 或 `.tar`）直接放到本仓库的根目录下。
3. 打开终端，进入本仓库目录，执行以下命令：
   ```bash
   caffeinate -dim zsh ./scripts/setup.sh
   ```
4. 如果你使用的是 `.tar` 离线包，现在就可以去喝杯咖啡了，程序会全自动完成安装；如果你用的是 `.bin` 在线包，终端会在中途提示你输入一次 AMD 的账号密码进行联网下载。

### 3. 使用方法 (GUI 图形界面模式)
安装完成后，只需在终端运行以下脚本，即可自动启动容器并唤出 macOS 的屏幕共享桌面：
```bash
./scripts/start_container.sh
```
*注：你的 Mac 仓库目录已经被自动挂载到了 Linux 容器内部的 `/home/user`。请将你的 FPGA 工程文件保存在这个目录下，以确保重启 Docker 后数据不会丢失。*

### 4. 使用方法 (CLI 纯命令行模式)
如果你只想通过命令行（Tcl 或 Makefile 模式）跑综合和编译，不需要图形界面：
```bash
docker start vivado_container
docker exec -it vivado_container bash
# 进入容器后，执行以下命令初始化环境变量：
source /home/user/Xilinx/Vivado/2025.2/settings64.sh
# 之后即可无界面运行 Vivado
vivado -mode tcl
```

## 📜 鸣谢与开源协议
* **项目维护者**: [ChenjiaXie](https://github.com/ChenjiaXie)
* **原项目作者**: [ichi4096](https://github.com/ichi4096/vivado-on-silicon-mac)
* 本仓库内容基于 Creative Commons Zero v1.0 Universal (CC0 1.0) 协议开源。
* Apple, Mac, Rosetta, Docker, AMD, Xilinx, 以及 Vivado 均为其各自所有者的注册商标。