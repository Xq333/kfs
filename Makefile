# Basic paths
ZIG = zig
KERNEL_BIN = zig-out/bin/kernel.elf
KERNEL_DST = boot/kernel
ISO_DIR = isodir
ISO_FILE = kernel.iso

# Colors for output
CYAN = \033[0;36m
GREEN = \033[0;32m
YELLOW = \033[0;33m
RESET = \033[0m

.PHONY: all build iso run re clean fclean help

# Default target - build and stage kernel for GRUB
all: build

build:
	@echo "$(CYAN)Building kernel via build.zig...$(RESET)"
	$(ZIG) build
	@mkdir -p $(dir $(KERNEL_DST))
	@if [ -d $(KERNEL_DST) ]; then rm -rf $(KERNEL_DST); fi
	@cp $(KERNEL_BIN) $(KERNEL_DST)
	@echo "$(GREEN)✓ Kernel ready at $(KERNEL_DST)!$(RESET)"

# Create bootable ISO with GRUB
iso: build
	@echo "$(CYAN)Creating bootable ISO...$(RESET)"
	@mkdir -p $(ISO_DIR)/boot/grub
	@cp $(KERNEL_DST) $(ISO_DIR)/boot/
	@cp boot/grub/grub.cfg $(ISO_DIR)/boot/grub/
	@grub-mkrescue -o $(ISO_FILE) $(ISO_DIR)
	@echo "$(GREEN)✓ Bootable ISO created: $(ISO_FILE)$(RESET)"

# Run kernel in QEMU
run: iso
	@echo "$(CYAN)Starting QEMU...$(RESET)"
	@qemu-system-x86_64 -cdrom $(ISO_FILE)

# Quick run without ISO (direct kernel boot)
run-kernel: build
	@echo "$(CYAN)Starting QEMU with direct kernel boot...$(RESET)"
	@qemu-system-x86_64 -kernel $(KERNEL_BIN)

# Rebuild - removes old files and rebuilds
re: fclean all

# Clean staged artifacts (keeps zig-out cache)
clean:
	@echo "$(CYAN)Removing staged kernel...$(RESET)"
	@if [ -d $(KERNEL_DST) ]; then rm -rf $(KERNEL_DST); elif [ -f $(KERNEL_DST) ]; then rm -f $(KERNEL_DST); fi
	@rm -rf $(ISO_DIR)
	@rm -f $(ISO_FILE)

# Full clean - remove everything Zig produced
fclean: clean 
	@rm -rf zig-out
	@rm -rf zig-cache
	@rm -rf .zig-cache

# Help target
help:
	@echo "Available targets:"
	@echo "  make / make build    - Build with build.zig and copy to boot/kernel"
	@echo "  make iso             - Build kernel and create bootable ISO"
	@echo "  make run             - Build ISO and run in QEMU"
	@echo "  make run-kernel      - Build and run kernel directly in QEMU (no ISO)"
	@echo "  make re              - Clean and rebuild"
	@echo "  make clean           - Remove staged files and ISO"
	@echo "  make fclean          - Remove staged files, ISO, and Zig caches"

