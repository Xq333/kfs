# sobOS

A minimal x86 kernel written in Zig by pfaria-d and evmorvan.

## Quick Start

```bash
make        # Build and run in QEMU
make run    # Same as above
make clean  # Remove build artifacts
```

## Features

- **5 Virtual Screens** - Switch with F1-F5
- **Real-time Boot Logging** - Watch system initialization as it happens
- **Interrupt-driven Keyboard** - PS/2 keyboard via IRQ1
- **VGA Text Mode** - 80x25 display with colors
- **Header Bar** - Persistent navigation bar

## Screens

| Key | Screen | Description |
|-----|--------|-------------|
| F1 | System | Real-time boot log showing GDT, IDT, PIC, drivers |
| F2 | Terminal | Interactive shell (keyboard input works here only) |
| F3 | ??? | Placeholder for future features |
| F4 | Help | Keyboard shortcuts reference |
| F5 | About | Credits and build info |

## Project Structure

```
kfs1/
├── boot/
│   └── grub/
│       └── grub.cfg          # GRUB bootloader configuration
├── src/
│   └── kernel/
│       ├── main.zig          # Kernel entry point
│       ├── arch/             # x86 architecture
│       │   ├── gdt.zig       # Global Descriptor Table
│       │   ├── idt.zig       # Interrupt Descriptor Table
│       │   ├── isr.zig       # Interrupt Service Routines
│       │   └── pic.zig       # Programmable Interrupt Controller
│       ├── drivers/          # Hardware drivers
│       │   ├── keyboard.zig  # PS/2 keyboard driver
│       │   └── vga.zig       # VGA & I/O ports
│       ├── io/               # I/O abstractions
│       │   ├── buffer.zig    # VGA text buffer
│       │   ├── console.zig   # Console API
│       │   ├── header.zig    # Header bar
│       │   └── screen.zig    # Virtual screen manager
│       ├── ui/               # Screen content
│       │   ├── syslog.zig    # System logger (logs to F1)
│       │   ├── terminal.zig  # Terminal screen (F2)
│       │   ├── help.zig      # Help screen (F4)
│       │   ├── about.zig     # About screen (F5)
│       │   └── empty.zig     # Placeholder screen (F3)
│       └── lib/              # Utilities
│           ├── colors.zig    # VGA color definitions
│           └── print.zig     # Formatted printing
├── build.zig                 # Zig build configuration
├── linker.ld                 # Linker script
├── Makefile                  # Build automation
└── shell.nix                 # Nix development environment
```

## Architecture

### Boot Sequence

1. **GRUB** loads kernel at 1MB via Multiboot
2. **`_start`** sets up stack, calls `kmain`
3. **Console init** - VGA, screen manager, header bar
4. **Architecture init** - GDT, IDT, PIC (each logs to F1 in real-time)
5. **Drivers init** - Console, keyboard (each logs to F1 in real-time)
6. **Screen setup** - Initialize F2-F5 content
7. **Enable interrupts** - `sti` instruction
8. **Main loop** - `hlt` until keyboard interrupt, process input

### Real-time Logging

Each component logs its status as it initializes to the System screen (F1):

```
Architecture
  [OK] GDT loaded (5 entries: null, kcode, kdata, ucode, udata)
  [OK] IDT loaded (256 interrupt gates)
  [OK] PIC remapped (IRQ 0-15 -> INT 32-47)
  [OK] IRQ1 (keyboard) unmasked

Drivers
  [OK] VGA text mode 80x25 at 0xB8000
  [OK] Console driver initialized
  [OK] PS/2 keyboard driver loaded

System
  [OK] 5 virtual screens initialized
  [OK] Header bar enabled
  [OK] Interrupts enabled (sti)

  System ready. Press F2 for terminal.
```

### Key Components

| File | Purpose |
|------|---------|
| `main.zig` | Entry point, orchestrates initialization |
| `ui/syslog.zig` | Logs to System screen (F1) from anywhere |
| `io/screen.zig` | Manages 5 virtual screen buffers |
| `io/header.zig` | Draws persistent header bar |
| `arch/gdt.zig` | Memory segmentation for protected mode |
| `arch/idt.zig` | Interrupt handler registration |
| `arch/pic.zig` | Hardware interrupt routing |
| `drivers/keyboard.zig` | PS/2 keyboard via IRQ1 |

### Interrupt Flow

```
Key press → IRQ1 → PIC → CPU → IDT → ISR → keyboard handler → buffer
                                                                  ↓
Main loop ← hlt wakes ← interrupt returns                    getChar()
```

## Key Concepts

### Virtual Screens
Each screen has its own 80x25 buffer. Switching screens (F1-F5):
1. Saves current VGA memory to old screen buffer
2. Loads new screen buffer to VGA memory
3. Restores cursor position and color
4. Redraws header bar

### hlt Instruction
```zig
asm volatile ("hlt");  // Sleep until interrupt
```
Saves CPU power by halting until keyboard interrupt wakes it.

### Protected Mode
- Flat memory model (4GB addressable)
- Ring 0 (kernel) privileges
- Hardware interrupt handling via IDT

## Adding New Features

### Adding a new screen content
1. Create `src/kernel/ui/myscreen.zig` with a `draw()` function
2. Import it in `main.zig`
3. Call `myscreen.draw()` in `setupScreens()`

### Adding system logs
Use `syslog` from anywhere:
```zig
const syslog = @import("ui/syslog.zig");

syslog.section("My Component");
syslog.ok("Something initialized");
syslog.fail("Something failed");
syslog.info("Some information");
```

## Resources

- [OSDev Wiki](https://wiki.osdev.org/)
- [Multiboot Specification](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html)
- [Intel x86 Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [Zig Language](https://ziglang.org/documentation/master/)
