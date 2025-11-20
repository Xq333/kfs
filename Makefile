# Basic paths
ZIG = zig
KERNEL_BIN = zig-out/bin/kernel.elf
KERNEL_DST = boot/kernel

# Colors for output
CYAN = \033[0;36m
GREEN = \033[0;32m
RESET = \033[0m

.PHONY: all build re clean fclean help

# Default target - build and stage kernel for GRUB
all: build

build:
	@echo "$(CYAN)Building kernel via build.zig...$(RESET)"
	$(ZIG) build
	@mkdir -p $(dir $(KERNEL_DST))
	@if [ -d $(KERNEL_DST) ]; then rm -rf $(KERNEL_DST); fi
	@cp $(KERNEL_BIN) $(KERNEL_DST)
	@echo "$(GREEN)✓ Kernel ready at $(KERNEL_DST)!$(RESET)"

# Rebuild - removes old files and rebuilds
re: fclean all

# Clean staged artifacts (keeps zig-out cache)
clean:
	@echo "$(CYAN)Removing staged kernel...$(RESET)"
	@if [ -d $(KERNEL_DST) ]; then rm -rf $(KERNEL_DST); elif [ -f $(KERNEL_DST) ]; then rm -f $(KERNEL_DST); fi

# Full clean - remove everything Zig produced
fclean: clean 
	@rm -rf zig-out
	@rm -rf zig-cache
	@rm -rf .zig-cache

# Help target
help:
	@echo "Available targets:"
	@echo "  make / make build  - Build with build.zig and copy to boot/kernel"
	@echo "  make re            - Clean and rebuild"
	@echo "  make clean         - Remove staged boot/kernel file"
	@echo "  make fclean        - Remove staged files and Zig caches"

