obj-m += hp-wmi.o

KVERSION ?= $(shell uname -r)
KERNEL_BUILD ?= /lib/modules/$(KVERSION)/build

# When KERNELRELEASE is set we are being re-read by the kernel build system.
# Only obj-m (above) is needed in that context — skip everything else.
ifeq ($(KERNELRELEASE),)

.DEFAULT_GOAL := all

# Check if the kernel was built with clang
ifeq ($(shell grep -q "CONFIG_CC_IS_CLANG=y" $(KERNEL_BUILD)/include/config/auto.conf 2>/dev/null && echo yes),yes)
    MAKE_OPTS += LLVM=1
endif

# Detect the platform_profile API variant by inspecting the installed kernel
# header and write the result to omen_pp_compat.h for hp-wmi.c to include.
# Using a generated header avoids the ccflags-y+= command-line override pitfall.
# The header may reside under KERNEL_BUILD or in a separate -common package
# (Debian splits kernel headers into arch-specific and common packages).

.PHONY: omen_pp_compat.h
omen_pp_compat.h:
	@PP_HDR=$$(find $(KERNEL_BUILD) /usr/src/linux-headers-* \
		-name platform_profile.h -path "*/linux/platform_profile.h" \
		2>/dev/null | head -1); \
	if grep -q "devm_platform_profile_register" "$$PP_HDR" 2>/dev/null; then \
		echo "#define OMEN_PP_API_NEW" > $@; \
	elif grep -q "platform_profile_handler" "$$PP_HDR" 2>/dev/null; then \
		echo "#define OMEN_PP_API_HANDLER" > $@; \
	else \
		echo "#define OMEN_PP_API_INTERMEDIATE" > $@; \
	fi
	@echo "  GEN     $@ ($$(cat $@))"

all: omen_pp_compat.h
	$(MAKE) -C $(KERNEL_BUILD) M=$(CURDIR) $(MAKE_OPTS) modules

clean:
	$(MAKE) -C $(KERNEL_BUILD) M=$(CURDIR) $(MAKE_OPTS) clean
	rm -f omen_pp_compat.h

install:
	sudo cp hp-wmi.ko /lib/modules/$(KVERSION)/kernel/drivers/platform/x86/hp/hp-wmi.ko
	sudo depmod -a

endif # ifeq ($(KERNELRELEASE),)
