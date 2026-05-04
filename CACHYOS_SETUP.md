# CachyOS Setup Guide

This guide provides specific instructions for setting up HP Omen Fan Control on CachyOS Linux.

## CachyOS-Specific Considerations

### Kernel Variants

CachyOS provides multiple kernel variants:
- `linux-cachyos` - Main CachyOS kernel (optimized)
- `linux-cachyos-lts` - Long-term support kernel
- `linux-cachyos-rc` - Release candidate kernel

### Clang/LLVM Kernels

CachyOS kernels are built with Clang/LLVM. The Makefile automatically detects this and passes the correct flags.

**No extra configuration needed.**

## Installation

### Step 1: Install Dependencies

```bash
sudo pacman -S linux-cachyos-headers base-devel python python-pip
```

### Step 2: Install Python Dependencies

```bash
pip install click PyQt6
```

### Step 3: Clone Repository

```bash
git clone https://github.com/WillSanCaZam/omen-fan-control.git
cd omen-fan-control
```

### Step 4: Install Driver

```bash
sudo ./install_driver.sh
```

### Step 5: Enable Autosustainable System

```bash
sudo ./hooks/install-autosustainable.sh
```

## Verification

### Check Driver Status

```bash
# Check if module is loaded
lsmod | grep hp-wmi

# Check PWM interface
ls /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1

# Read current PWM value
cat /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1
```

### Test Fan Control

```bash
# Check status
python3 omen_cli.py status

# Set fan speed to 50%
python3 omen_cli.py fan 50

# Set fan speed to auto
python3 omen_cli.py fan auto
```

## System Updates

When running `cachy-update`, the system automatically:
1. Detects kernel updates
2. Recompiles the driver via DKMS
3. Verifies the driver is loaded
4. Logs all operations

**No manual intervention required.**

## Troubleshooting

### Driver Not Loading After Update

```bash
# Check DKMS status
dkms status hp-wmi-omen

# Reinstall module
sudo dkms install hp-wmi-omen/1.0 -k $(uname -r) --force

# Reload module
sudo modprobe -r hp-wmi
sudo modprobe hp-wmi
```

### PWM Interface Not Found

```bash
# Run verification script
sudo /usr/local/bin/hp-wmi-omen-verify.sh

# Check logs
cat /var/log/hp-wmi-omen-verify.log
```

### Kernel Build Errors

```bash
# Check kernel headers
ls /lib/modules/$(uname -r)/build

# Reinstall headers
sudo pacman -S linux-cachyos-headers

# Clean and rebuild
make clean
make
```

## Logs

### Verification Logs
```bash
cat /var/log/hp-wmi-omen-verify.log
```

### DKMS Logs
```bash
cat /var/log/hp-wmi-omen-dkms.log
```

### Systemd Logs
```bash
journalctl -u hp-wmi-omen-verify -f
```

## Uninstallation

```bash
sudo ./hooks/uninstall-autosustainable.sh
```

## Additional Resources

- [CachyOS Wiki](https://wiki.cachyos.org/)
- [Arch Linux Wiki - DKMS](https://wiki.archlinux.org/title/Dynamic_Kernel_Module_Support)
- [Main README](README.md)