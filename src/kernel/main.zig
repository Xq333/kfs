const console = @import("io/console.zig");
const keyboard = @import("drivers/keyboard.zig");
const screen = @import("io/screen.zig");
const header = @import("io/header.zig");
const gdt = @import("arch/gdt.zig");
const idt = @import("arch/idt.zig");
const pic = @import("arch/pic.zig");

// UI screens
const syslog = @import("ui/syslog.zig");
const terminal = @import("ui/terminal.zig");
const help = @import("ui/help.zig");
const about = @import("ui/about.zig");
const empty = @import("ui/empty.zig");

// ============================================================================
// Multiboot Header
// ============================================================================

const MB_HEADER_MAGIC = 0x1BADB002;
const MB_FLAG_ALIGN = 1 << 0;
const MB_FLAG_MEMINFO = 1 << 1;
const FLAGS = MB_FLAG_ALIGN | MB_FLAG_MEMINFO;

const MultibootHeader = packed struct {
    magic: u32 = MB_HEADER_MAGIC,
    flags: u32 = FLAGS,
    checksum: u32,
    padding: u32 = 0,
};

export var multiboot: MultibootHeader align(4) linksection(".multiboot") = .{
    .checksum = ~@as(u32, (MB_HEADER_MAGIC + FLAGS)) + 1,
};

// ============================================================================
// Stack
// ============================================================================

var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\ movl %[stack_top], %%esp
        \\ movl %%esp, %%ebp
        \\ call %[kmain:P]
        :
        : [stack_top] "i" (&@as([*]align(16) u8, @ptrCast(&stack_bytes))[stack_bytes.len]),
          [kmain] "X" (&kmain),
    );
}

// ============================================================================
// Initialization
// ============================================================================

fn initConsole() void {
    console.init();
    screen.init();
    header.draw();
    printBanner();
}

fn initArch() void {
    syslog.section("Architecture");
    gdt.init(); // Logs: GDT loaded
    idt.init(); // Logs: IDT loaded
    pic.init(); // Logs: PIC remapped, IRQ1 unmasked
    syslog.newline();
}

fn initDrivers() void {
    syslog.section("Drivers");
    syslog.ok("VGA text mode 80x25 at 0xB8000");
    syslog.ok("Console driver initialized");
    keyboard.init(); // Logs: PS/2 keyboard driver loaded
    syslog.newline();
}

fn printBanner() void {
    console.print("\n", .{});
    console.printColored("  =========================================\n", .{}, .cyan, .black);
    console.printColored("  Welcome to ", .{}, .white, .black);
    console.printColored("sobOS", .{}, .light_green, .black);
    console.printColored(" by pfaria-d and evmorvan\n", .{}, .white, .black);
    console.printColored("  =========================================\n", .{}, .cyan, .black);
    console.print("\n", .{});
}

fn setupScreens() void {
    // Screen 1 (F2): Terminal
    screen.switchTo(1);
    terminal.draw();

    // Screen 2 (F3): Empty placeholder
    screen.switchTo(2);
    empty.draw();

    // Screen 3 (F4): Help
    screen.switchTo(3);
    help.draw();

    // Screen 4 (F5): About
    screen.switchTo(4);
    about.draw();

    // Go back to System screen (F1)
    screen.switchTo(0);
}

fn finishBoot() void {
    syslog.section("System");
    syslog.ok("5 virtual screens initialized");
    syslog.ok("Header bar enabled");
    syslog.ok("Interrupts enabled (sti)");
    syslog.newline();
    syslog.info("System ready. Press F2 for terminal.");
}

// ============================================================================
// Kernel Main
// ============================================================================

noinline fn kmain() callconv(.c) noreturn {
    // Initialize console first (so we can see logs)
    initConsole();

    // Initialize architecture (logs to System screen)
    initArch();

    // Initialize drivers (logs to System screen)
    initDrivers();

    // Setup all other screens
    setupScreens();

    // Enable interrupts
    idt.enableInterrupts();

    // Final boot messages
    finishBoot();

    // Main loop: hlt until interrupt, then check for input
    while (true) {
        // hlt: Halt the CPU until the next interrupt occurs.
        // This saves power by stopping execution instead of spinning.
        // When a hardware interrupt fires (e.g., keyboard IRQ1), the CPU
        // wakes up, the interrupt handler runs, and execution continues here.
        // asm volatile: inline assembly that the compiler won't optimize away.
        asm volatile ("hlt");

        while (keyboard.getChar()) |char| {
            // Only accept keyboard input on Terminal screen (F2)
            if (screen.getActiveScreen() == 1) {
                console.printChar(char);
                // Print new prompt after Enter
                if (char == '\n') {
                    terminal.printPrompt();
                }
            }
        }
    }
}
