# Autosustainable System

This document describes the ultra-autosustainable system for HP Omen Fan Control, ensuring automatic recovery after system updates.

## Overview

The autosustainable system provides **7 layers of protection** to ensure fan control works reliably after any system update or kernel upgrade.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Layer 1: Pacman Hook                  │
│  Detects kernel updates → Recompiles driver via DKMS    │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              Layer 2: Systemd Service                   │
│  Verifies driver at system startup                      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│               Layer 3: Systemd Timer                    │
│  Monitors driver status every hour                      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│            Layer 4: Verification Script                 │
│  Multi-layer verification with automatic retry         │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              Layer 5: Logging System                   │
│  Centralized logging with automatic rotation            │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│          Layer 6: Installation Script                   │
│  Automated installation of all components               │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│           Layer 7: Uninstallation Script                │
│  Clean removal of all components                        │
└─────────────────────────────────────────────────────────┘
```

## Components

### 1. Pacman Hook (`/etc/pacman.d/hooks/90-hp-wmi-omen.hook`)

**Purpose:** Automatically recompile driver after kernel updates.

**Triggers:**
- `linux-cachyos` updates
- `linux-cachyos-lts` updates
- `linux-cachyos-rc` updates
- Standard Arch kernel updates (fallback)

**Action:**
```bash
dkms autoinstall -k $kernelver
```

**Logs:** `/var/log/hp-wmi-omen-dkms.log`

### 2. Systemd Service (`/etc/systemd/system/hp-wmi-omen-verify.service`)

**Purpose:** Verify driver at system startup.

**Conditions:**
- Only runs if HP Omen hardware is detected
- Only runs if `/sys/devices/platform/hp-wmi` exists

**Action:** Executes verification script

**Logs:** Systemd journal (`journalctl -u hp-wmi-omen-verify`)

### 3. Systemd Timer (`/etc/systemd/system/hp-wmi-omen-verify.timer`)

**Purpose:** Monitor driver status periodically.

**Schedule:** Every hour

**Features:**
- Persistent (runs if system was off)
- Randomized startup (up to 5 minutes)
- High accuracy (1 second)

### 4. Verification Script (`/usr/local/bin/hp-wmi-omen-verify.sh`)

**Purpose:** Multi-layer verification with automatic recovery.

**Checks:**
1. Hardware compatibility (DMI board name)
2. Module loaded status
3. PWM interface availability
4. PWM value readability

**Recovery:**
- Automatic retry (up to 3 attempts)
- DKMS rebuild if retry fails
- Rollback to original driver if rebuild fails

**Logs:** `/var/log/hp-wmi-omen-verify.log`

### 5. Logging System (`/etc/logrotate.d/hp-wmi-omen`)

**Purpose:** Centralized logging with automatic rotation.

**Configuration:**
- Verification logs: Daily, 7 days retention
- DKMS logs: Weekly, 4 weeks retention
- Automatic compression
- Automatic cleanup

### 6. Installation Script (`hooks/install-autosustainable.sh`)

**Purpose:** Automated installation of all components.

**Steps:**
1. Install pacman hook
2. Install systemd service
3. Install systemd timer
4. Install verification script
5. Install logrotate configuration
6. Create log files
7. Reload systemd
8. Enable and start services
9. Run initial verification

**Usage:**
```bash
sudo ./hooks/install-autosustainable.sh
```

### 7. Uninstallation Script (`hooks/uninstall-autosustainable.sh`)

**Purpose:** Clean removal of all components.

**Steps:**
1. Stop and disable services
2. Remove systemd files
3. Remove pacman hook
4. Remove verification script
5. Remove logrotate configuration
6. Ask about DKMS module removal
7. Ask about log file removal

**Usage:**
```bash
sudo ./hooks/uninstall-autosustainable.sh
```

## Workflow

### System Update Workflow

```
1. User runs `cachy-update`
   ↓
2. Pacman detects kernel update
   ↓
3. Hook triggers (PostTransaction)
   ↓
4. DKMS recompiles driver
   ↓
5. Driver installed for new kernel
   ↓
6. System reboots (if required)
   ↓
7. Systemd service verifies driver
   ↓
8. Timer monitors periodically
   ↓
9. All operations logged
```

### Failure Recovery Workflow

```
1. Verification detects failure
   ↓
2. Automatic retry (attempt 1/3)
   ↓
3. If retry fails → DKMS rebuild
   ↓
4. If rebuild fails → Rollback
   ↓
5. All steps logged
   ↓
6. System remains functional
```

## Monitoring

### Check Status

```bash
# Check timer status
systemctl status hp-wmi-omen-verify.timer

# Check service status
systemctl status hp-wmi-omen-verify.service

# Check next timer execution
systemctl list-timers | grep hp-wmi
```

### View Logs

```bash
# Verification logs
cat /var/log/hp-wmi-omen-verify.log

# DKMS logs
cat /var/log/hp-wmi-omen-dkms.log

# Systemd logs
journalctl -u hp-wmi-omen-verify -f

# Follow all logs
tail -f /var/log/hp-wmi-omen-verify.log
```

### Manual Verification

```bash
# Run verification manually
sudo /usr/local/bin/hp-wmi-omen-verify.sh

# Check result
echo $?
```

## Troubleshooting

### Timer Not Running

```bash
# Check if timer is enabled
systemctl is-enabled hp-wmi-omen-verify.timer

# Enable timer
sudo systemctl enable hp-wmi-omen-verify.timer

# Start timer
sudo systemctl start hp-wmi-omen-verify.timer
```

### Service Not Starting

```bash
# Check service status
systemctl status hp-wmi-omen-verify.service

# Check service logs
journalctl -u hp-wmi-omen-verify -n 50

# Manually start service
sudo systemctl start hp-wmi-omen-verify.service
```

### Verification Failing

```bash
# Run verification with verbose output
sudo /usr/local/bin/hp-wmi-omen-verify.sh

# Check logs
cat /var/log/hp-wmi-omen-verify.log

# Check hardware detection
cat /sys/class/dmi/id/board_name

# Check module status
lsmod | grep hp-wmi

# Check PWM interface
ls /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1
```

### DKMS Build Failing

```bash
# Check DKMS status
dkms status hp-wmi-omen

# Rebuild module
sudo dkms build hp-wmi-omen/1.0 -k $(uname -r)

# Install module
sudo dkms install hp-wmi-omen/1.0 -k $(uname -r)

# Check logs
cat /var/log/hp-wmi-omen-dkms.log
```

## Performance Impact

### Resource Usage

- **Timer:** Minimal (runs once per hour)
- **Service:** Negligible (runs once at startup)
- **Verification Script:** < 1 second execution time
- **Logging:** < 1MB per day

### System Load

- **Startup:** < 0.1s additional time
- **Periodic:** < 0.01s CPU time per hour
- **Disk:** < 10MB total (logs + configs)

## Security

### Permissions

- **Hook:** Root required (system-level)
- **Service:** Root required (system-level)
- **Timer:** Root required (system-level)
- **Verification Script:** Root required (module operations)

### Access Control

- **Logs:** Root read/write, user read-only
- **Configs:** Root read/write
- **Scripts:** Root execute, user read-only

## Maintenance

### Updates

The system automatically handles:
- Kernel updates
- Driver recompilation
- Service restarts
- Log rotation

**No manual maintenance required.**

### Monitoring

Recommended monitoring:
- Check logs weekly
- Verify timer status monthly
- Review DKMS status after major kernel updates

## Uninstallation

To remove the autosustainable system:

```bash
sudo ./hooks/uninstall-autosustainable.sh
```

This will:
- Stop and disable all services
- Remove all systemd files
- Remove pacman hook
- Remove verification script
- Remove logrotate configuration
- Ask about DKMS module removal
- Ask about log file removal

## Additional Resources

- [Main README](README.md)
- [CachyOS Setup](CACHYOS_SETUP.md)
- [Hardware Patches](PATCHES.md)
- [Systemd Documentation](https://www.freedesktop.org/software/systemd/man/)
- [DKMS Documentation](https://wiki.archlinux.org/title/Dynamic_Kernel_Module_Support)
