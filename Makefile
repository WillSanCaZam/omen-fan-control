obj-m += hp-wmi.o

KVERSION ?= $(shell uname -r)
KERNEL_BUILD ?= /lib/modules/$(KVERSION)/build

# Check if the kernel was built with clang
ifeq ($(shell grep -q "CONFIG_CC_IS_CLANG=y" $(KERNEL_BUILD)/include/config/auto.conf 2>/dev/null && echo yes),yes)
    MAKE_OPTS += LLVM=1
endif

all:
	$(MAKE) -C $(KERNEL_BUILD) M=$(CURDIR) $(MAKE_OPTS) modules

clean:
	$(MAKE) -C $(KERNEL_BUILD) M=$(CURDIR) $(MAKE_OPTS) clean

install:
	sudo cp hp-wmi.ko /lib/modules/$(KVERSION)/kernel/drivers/platform/x86/hp/hp-wmi.ko
	sudo depmod -a
