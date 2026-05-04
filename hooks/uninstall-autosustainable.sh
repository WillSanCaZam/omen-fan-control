#!/bin/bash
# HP Omen Fan Control - Clean Uninstallation Script
# Removes all autosustainable components

set -e

LOG_FILE="/var/log/hp-wmi-omen-uninstall.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Starting Clean Uninstallation"
log "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

# Step 1: Stop and disable services
log "Step 1: Stopping and disabling services..."
systemctl stop hp-wmi-omen-verify.timer 2>/dev/null || true
systemctl stop hp-wmi-omen-verify.service 2>/dev/null || true
systemctl disable hp-wmi-omen-verify.timer 2>/dev/null || true
systemctl disable hp-wmi-omen-verify.service 2>/dev/null || true
log "Services stopped and disabled"

# Step 2: Remove systemd files
log "Step 2: Removing systemd files..."
rm -f /etc/systemd/system/hp-wmi-omen-verify.service
rm -f /etc/systemd/system/hp-wmi-omen-verify.timer
systemctl daemon-reload
log "Systemd files removed"

# Step 3: Remove pacman hook
log "Step 3: Removing pacman hook..."
rm -f /etc/pacman.d/hooks/90-hp-wmi-omen.hook
log "Pacman hook removed"

# Step 4: Remove verification script
log "Step 4: Removing verification script..."
rm -f /usr/local/bin/hp-wmi-omen-verify.sh
log "Verification script removed"

# Step 5: Remove logrotate configuration
log "Step 5: Removing logrotate configuration..."
rm -f /etc/logrotate.d/hp-wmi-omen-logrotate.conf
log "Logrotate configuration removed"

# Step 6: Ask about DKMS module
log "Step 6: DKMS module removal..."
read -p "Do you want to remove the DKMS module? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Removing DKMS module..."
    dkms remove hp-wmi-omen/1.0 --all 2>/dev/null || true
    rm -rf /usr/src/hp-wmi-omen-1.0
    log "DKMS module removed"
else
    log "DKMS module kept"
fi

# Step 7: Ask about log files
log "Step 7: Log files removal..."
read -p "Do you want to remove log files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Removing log files..."
    rm -f /var/log/hp-wmi-omen-verify.log
    rm -f /var/log/hp-wmi-omen-dkms.log
    log "Log files removed"
else
    log "Log files kept"
fi

log "=========================================="
log "Uninstallation completed!"
log "=========================================="
log ""
log "Note: The driver module might still be loaded."
log "To unload it, run: sudo modprobe -r hp-wmi"
log "To reload the original driver, run: sudo modprobe hp-wmi"
log ""
log "=========================================="