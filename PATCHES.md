# Hardware-Specific Patches

This document describes hardware-specific patches for different HP Omen and Victus models.

## Supported Hardware

### HP Omen 16-wd0xxx (Board 8BA9)

**Status:** ✅ Tested and Working

**System:** CachyOS Linux
**Kernel:** 7.0.3-1-cachyos

**Patch Details:**
- Added DMI match for board name "8BA9"
- Uses `omen_v1_thermal_params` for thermal management
- Enables manual fan control via PWM interface

**Code Changes:**
```c
{
    .matches = {DMI_MATCH(DMI_BOARD_NAME, "8BA9")},
    .driver_data = (void *)&omen_v1_thermal_params,
},
```

**Installation:**
1. Install kernel headers: `sudo pacman -S linux-cachyos-headers base-devel`
2. Run installation script: `sudo ./install_driver.sh`
3. Enable autosustainable system: `sudo ./hooks/install-autosustainable.sh`

**Verification:**
```bash
# Check if module is loaded
lsmod | grep hp-wmi

# Check PWM interface
ls /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1

# Test fan control
python3 omen_cli.py status
```

**Known Issues:**
- None

**References:**
- Original kernel commit: [platform/x86: hp-wmi: add manual fan control for Victus S models](https://git.kernel.org/pub/scm/linux/kernel/git/pdx86/platform-drivers-x86.git/commit/?h=for-next&id=46be1453e6e61884b4840a768d1e8ffaf01a4c1c)

## Adding New Patches

To add support for a new hardware model:

1. Identify the board name: `cat /sys/class/dmi/id/board_name`
2. Determine the appropriate thermal profile
3. Add DMI match to `hp-wmi.c`
4. Test thoroughly
5. Update this document
6. Submit pull request

## Thermal Profiles

Available thermal profiles:
- `omen_v1_thermal_params` - For Omen V1 models
- `victus_s_thermal_params` - For Victus S models
- `victus_s_thermal_params_v2` - For Victus S V2 models

Choose the appropriate profile based on your hardware testing.