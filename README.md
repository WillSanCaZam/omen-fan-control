# HP Omen Fan Control (Linux)

This tool provides fan control for HP Omen Max, Victus and Omen laptops on Linux. It includes installer for a kernel driver patch (`hp-wmi`) to expose PWM controls and a userspace utility to manage fan curves, create watchdog that sets the fan configuration periodically and a simple stress test tool to see the fan curve in effect.

## Context

This tool includes a backported `hp-wmi` driver patch from the upcoming Linux 6.20 kernel, which introduces native fan control support for many devices from the following models:
1.  **HP Omen Max**
2.  **HP Victus**
3.  **HP Omen**

The patch can be installed on versions before `6.20`.

**Reference Kernel Commit:**
[platform/x86: hp-wmi: add manual fan control for Victus S models](https://git.kernel.org/pub/scm/linux/kernel/git/pdx86/platform-drivers-x86.git/commit/?h=for-next&id=46be1453e6e61884b4840a768d1e8ffaf01a4c1c)

This program also includes a modification that sets the max speed according to calibration if the query to get the Max RPM fails for your device.

## Hardware-Specific Patches

This project includes hardware-specific patches for different HP Omen and Victus models. For detailed information about supported hardware and how to add new patches, see [PATCHES.md](PATCHES.md).

**Currently Supported Models:**
- HP Omen Max 16-AH0001NT (8D41)
- HP Omen 16-wd0xxx (8BA9)
- HP Victus S models
- Various other Omen and Victus models

## CachyOS Support

For CachyOS-specific installation instructions and troubleshooting, see [CACHYOS_SETUP.md](CACHYOS_SETUP.md).

**CachyOS Features:**
- Automatic detection of Clang/LLVM kernels
- Support for all CachyOS kernel variants
- Optimized for CachyOS performance

## Autosustainable System

This project includes an ultra-autosustainable system with 7 layers of protection to ensure fan control works reliably after any system update. For detailed information, see [AUTOSUSTAINABLE.md](AUTOSUSTAINABLE.md).

**Features:**
- Automatic driver recompilation after kernel updates
- System startup verification
- Periodic monitoring (hourly)
- Automatic recovery with retry logic
- Centralized logging with rotation
- Automated installation and uninstallation

## Tested Hardware

*   **Model:** HP OMEN MAX 16-AH0001NT (8D41)
*   **OS:** Arch Linux 6.18.6

*   **Model:** HP Omen 16-wd0xxx (8BA9)
*   **OS:** CachyOS Linux 7.0.3-1-cachyos