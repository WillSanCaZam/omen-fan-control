#!/bin/bash
# HP Omen Fan Control - Ultra-Robust Verification Script
# Multi-layer verification with automatic retry and rollback

set -o pipefail

# Configuration
LOG_FILE="/var/log/hp-wmi-omen-verify.log"
MODULE_NAME="hp-wmi"
MAX_RETRIES=3
RETRY_DELAY=5
BACKUP_DRIVER="/lib/modules/$(uname -r)/kernel/drivers/platform/x86/hp/hp-wmi.ko.bak"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Check if we're running on the right hardware
check_hardware() {
    log "INFO" "Checking hardware compatibility..."

    if [ ! -d "/sys/devices/platform/${MODULE_NAME}" ]; then
        log "WARNING" "Hardware platform not found: /sys/devices/platform/${MODULE_NAME}"
        log "INFO" "This might not be an HP Omen device, skipping verification"
        return 1
    fi

    # Check for DMI board name
    if [ -f "/sys/class/dmi/id/board_name" ]; then
        BOARD_NAME=$(cat /sys/class/dmi/id/board_name)
        log "INFO" "Board name: $BOARD_NAME"

        # Check if this is an Omen board (8BA9 or similar)
        if echo "$BOARD_NAME" | grep -qE "8BA[0-9]|OMEN"; then
            log "INFO" "HP Omen hardware detected"
            return 0
        else
            log "WARNING" "Non-OMEN board detected: $BOARD_NAME"
            log "INFO" "Driver might not be needed for this hardware"
            return 1
        fi
    fi

    log "INFO" "Hardware check passed"
    return 0
}

# Check if module is loaded
check_module_loaded() {
    log "INFO" "Checking if module is loaded..."

    if lsmod | grep -q "^${MODULE_NAME} "; then
        log "INFO" "Module ${MODULE_NAME} is loaded"
        return 0
    else
        log "WARNING" "Module ${MODULE_NAME} is NOT loaded"
        return 1
    fi
}

# Check if PWM interface exists and is accessible
check_pwm_interface() {
    log "INFO" "Checking PWM interface..."

    if [ ! -d "/sys/devices/platform/${MODULE_NAME}/hwmon" ]; then
        log "ERROR" "hwmon directory not found"
        return 1
    fi

    PWM_COUNT=$(find /sys/devices/platform/${MODULE_NAME}/hwmon -name "pwm1" 2>/dev/null | wc -l)

    if [ "$PWM_COUNT" -eq 0 ]; then
        log "ERROR" "PWM interface not found (0 instances)"
        return 1
    fi

    log "INFO" "PWM interface found (${PWM_COUNT} instance(s))"

    # Try to read PWM value
    PWM_PATH=$(find /sys/devices/platform/${MODULE_NAME}/hwmon -name "pwm1" 2>/dev/null | head -1)
    if [ -n "$PWM_PATH" ]; then
        if [ -r "$PWM_PATH" ]; then
            PWM_VALUE=$(cat "$PWM_PATH" 2>/dev/null || echo "unreadable")
            log "INFO" "PWM value: $PWM_VALUE"
            return 0
        else
            log "ERROR" "PWM interface exists but is not readable"
            return 1
        fi
    fi

    return 1
}

# Try to reload the module
reload_module() {
    local attempt=$1
    log "INFO" "Attempt $attempt: Reloading module..."

    # Try to unload the module
    if modprobe -r "$MODULE_NAME" 2>/dev/null; then
        log "INFO" "Module unloaded successfully"
    else
        log "WARNING" "Could not unload module (might be in use)"
    fi

    # Try to load the module
    if modprobe "$MODULE_NAME"; then
        log "INFO" "Module loaded successfully"
        return 0
    else
        log "ERROR" "Failed to load module"
        return 1
    fi
}

# Try to rebuild the module using DKMS
rebuild_module() {
    log "INFO" "Attempting to rebuild module using DKMS..."

    local kernel_version=$(uname -r)

    if dkms build -m hp-wmi-omen -v 1.0 -k "$kernel_version" 2>&1 | tee -a "$LOG_FILE"; then
        log "INFO" "DKMS build successful"

        if dkms install -m hp-wmi-omen -v 1.0 -k "$kernel_version" 2>&1 | tee -a "$LOG_FILE"; then
            log "INFO" "DKMS install successful"
            return 0
        else
            log "ERROR" "DKMS install failed"
            return 1
        fi
    else
        log "ERROR" "DKMS build failed"
        return 1
    fi
}

# Try to rollback to original driver
rollback_driver() {
    log "WARNING" "Attempting rollback to original driver..."

    if [ -f "$BACKUP_DRIVER" ]; then
        log "INFO" "Backup driver found: $BACKUP_DRIVER"

        local current_driver="/lib/modules/$(uname -r)/kernel/drivers/platform/x86/hp/hp-wmi.ko"

        if [ -f "$current_driver" ]; then
            log "INFO" "Removing current driver: $current_driver"
            rm -f "$current_driver"
        fi

        log "INFO" "Restoring backup driver"
        cp "$BACKUP_DRIVER" "$current_driver"

        log "INFO" "Running depmod"
        depmod -a

        log "INFO" "Reloading module"
        if modprobe -r "$MODULE_NAME" 2>/dev/null; then
            modprobe "$MODULE_NAME"
        fi

        log "INFO" "Rollback completed"
        return 0
    else
        log "ERROR" "Backup driver not found: $BACKUP_DRIVER"
        log "ERROR" "Cannot rollback automatically"
        return 1
    fi
}

# Main verification logic
main() {
    log "INFO" "=========================================="
    log "INFO" "Starting HP Omen Fan Control verification"
    log "INFO" "=========================================="

    # Check hardware compatibility
    if ! check_hardware; then
        log "INFO" "Hardware check failed or not applicable, exiting"
        exit 0
    fi

    # Check if module is loaded
    if ! check_module_loaded; then
        log "WARNING" "Module not loaded, attempting reload..."

        for attempt in $(seq 1 $MAX_RETRIES); do
            if reload_module "$attempt"; then
                log "INFO" "Module reload successful on attempt $attempt"
                break
            else
                log "WARNING" "Module reload failed on attempt $attempt"

                if [ "$attempt" -lt "$MAX_RETRIES" ]; then
                    log "INFO" "Waiting ${RETRY_DELAY}s before retry..."
                    sleep "$RETRY_DELAY"
                else
                    log "ERROR" "All reload attempts failed"
                    log "INFO" "Attempting to rebuild module..."

                    if rebuild_module; then
                        log "INFO" "Module rebuild successful, retrying load..."
                        if modprobe "$MODULE_NAME"; then
                            log "INFO" "Module loaded successfully after rebuild"
                            break
                        else
                            log "ERROR" "Failed to load module after rebuild"
                            log "WARNING" "Attempting rollback to original driver..."

                            if rollback_driver; then
                                log "INFO" "Rollback successful"
                                exit 1
                            else
                                log "ERROR" "Rollback failed"
                                exit 1
                            fi
                        fi
                    else
                        log "ERROR" "Module rebuild failed"
                        log "WARNING" "Attempting rollback to original driver..."

                        if rollback_driver; then
                            log "INFO" "Rollback successful"
                            exit 1
                        else
                            log "ERROR" "Rollback failed"
                            exit 1
                        fi
                    fi
                fi
            fi
        done
    fi

    # Check PWM interface
    if ! check_pwm_interface; then
        log "ERROR" "PWM interface check failed"
        log "WARNING" "Attempting module reload..."

        if reload_module 1; then
            log "INFO" "Module reload successful"

            if check_pwm_interface; then
                log "INFO" "PWM interface check passed after reload"
            else
                log "ERROR" "PWM interface still not working after reload"
                exit 1
            fi
        else
            log "ERROR" "Module reload failed"
            exit 1
        fi
    fi

    log "INFO" "=========================================="
    log "INFO" "Verification PASSED"
    log "INFO" "=========================================="
    exit 0
}

# Run main function
main