#!/bin/bash
# HP Omen Fan Control - Ultra-Autosustainable Installation Script
# Installs all components for maximum reliability

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/hp-wmi-omen-install.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Starting Ultra-Autosustainable Installation"
log "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

# Step 1: Install pacman hook
log "Step 1: Installing pacman hook..."
mkdir -p /etc/pacman.d/hooks
cp "$SCRIPT_DIR/90-hp-wmi-omen.hook" /etc/pacman.d/hooks/
chmod 644 /etc/pacman.d/hooks/90-hp-wmi-omen.hook
log "Pacman hook installed"

# Step 2: Install systemd service
log "Step 2: Installing systemd service..."
cp "$SCRIPT_DIR/hp-wmi-omen-verify.service" /etc/systemd/system/
chmod 644 /etc/systemd/system/hp-wmi-omen-verify.service
log "Systemd service installed"

# Step 3: Install systemd timer
log "Step 3: Installing systemd timer..."
cp "$SCRIPT_DIR/hp-wmi-omen-verify.timer" /etc/systemd/system/
chmod 644 /etc/systemd/system/hp-wmi-omen-verify.timer
log "Systemd timer installed"

# Step 4: Install verification script
log "Step 4: Installing verification script..."
cp "$SCRIPT_DIR/hp-wmi-omen-verify.sh" /usr/local/bin/
chmod 755 /usr/local/bin/hp-wmi-omen-verify.sh
log "Verification script installed"

# Step 5: Install logrotate configuration
log "Step 5: Installing logrotate configuration..."
mkdir -p /etc/logrotate.d
cp "$SCRIPT_DIR/hp-wmi-omen-logrotate.conf" /etc/logrotate.d/hp-wmi-omen
chmod 644 /etc/logrotate.d/hp-wmi-omen
log "Logrotate configuration installed"

# Step 6: Create log files
log "Step 6: Creating log files..."
touch /var/log/hp-wmi-omen-verify.log
touch /var/log/hp-wmi-omen-dkms.log
chmod 644 /var/log/hp-wmi-omen-verify.log
chmod 644 /var/log/hp-wmi-omen-dkms.log
log "Log files created"

# Step 7: Reload systemd
log "Step 7: Reloading systemd..."
systemctl daemon-reload
log "Systemd reloaded"

# Step 8: Enable and start services
log "Step 8: Enabling and starting services..."
systemctl enable hp-wmi-omen-verify.service
systemctl enable hp-wmi-omen-verify.timer
systemctl start hp-wmi-omen-verify.timer
log "Services enabled and started"

# Step 9: Run initial verification
log "Step 9: Running initial verification..."
/usr/local/bin/hp-wmi-omen-verify.sh
log "Initial verification completed"

# Step 10: Display status
log "=========================================="
log "Installation completed successfully!"
log "=========================================="
log ""
log "Installed components:"
log "  - Pacman hook: /etc/pacman.d/hooks/90-hp-wmi-omen.hook"
log "  - Systemd service: /etc/systemd/system/hp-wmi-omen-verify.service"
log "  - Systemd timer: /etc/systemd/system/hp-wmi-omen-verify.timer"
log "  - Verification script: /usr/local/bin/hp-wmi-omen-verify.sh"
log "  - Logrotate config: /etc/logrotate.d/hp-wmi-omen-logrotate.conf"
log ""
log "Log files:"
log "  - Verification: /var/log/hp-wmi-omen-verify.log"
log "  - DKMS: /var/log/hp-wmi-omen-dkms.log"
log ""
log "Systemd commands:"
log "  - Check status: systemctl status hp-wmi-omen-verify.service"
log "  - Check timer: systemctl status hp-wmi-omen-verify.timer"
log "  - View logs: journalctl -u hp-wmi-omen-verify"
log ""
log "=========================================="