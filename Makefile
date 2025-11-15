# Compiler and flags
ZIG = zig
BUILD_MODE = ReleaseSmall

# Zig equivalent flags for GCC flags:
# -fno-builtin         → Not applicable (Zig handles this differently)
# -fno-exception       → Not applicable (Zig doesn't use exceptions)
# -fno-stack-protector → -fno-stack-check
# -fno-rtti            → Not applicable (Zig doesn't have RTTI)
# -nostdlib            → -c (compile only, don't link) or using object files
# -nodefaultlibs       → Minimal linking approach
ZIG_FLAGS = -O $(BUILD_MODE) -fno-stack-check -fstrip -femit-bin=$(BIN)

# Source and binary files
SRC = main.zig
BIN = main

# Colors for output
CYAN = \033[0;36m
GREEN = \033[0;32m
RESET = \033[0m

.PHONY: all re clean fclean help

# Default target - compile the program
all: $(BIN)
	@echo "$(GREEN)✓ Build complete!$(RESET)"

# Direct compilation (most efficient for Zig)
$(BIN): $(SRC)
	@echo "$(CYAN)Building executable...$(RESET)"
	$(ZIG) build-exe $(ZIG_FLAGS) $(SRC)

# Rebuild - removes old files and rebuilds
re: fclean all

# Clean binary files
clean:
	@echo "$(CYAN)Removing binary files...$(RESET)"
	@rm -f $(BIN)
	@rm -f zig-cache

# Full clean - remove everything (same as clean for now)
fclean: clean

# Help target
help:
	@echo "Available targets:"
	@echo "  make      - Build the executable"
	@echo "  make re   - Rebuild (clean and build)"
	@echo "  make clean - Remove binary files"
	@echo "  make fclean - Remove all generated files"

