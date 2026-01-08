const console = @import("io/console.zig");
const keyboard = @import("drivers/keyboard.zig");
const gdt = @import("arch/gdt.zig");
const idt = @import("arch/idt.zig");
const pic = @import("arch/pic.zig");

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

fn initArch() void {
    gdt.init();
    idt.init();
    pic.init();
}

fn initDrivers() void {
    console.init();
    keyboard.init();
}

fn printStatus(comptime msg: []const u8) void {
    console.printColored("  [", .{}, .white, .black);
    console.printColored("OK", .{}, .green, .black);
    console.printColored("]", .{}, .white, .black);
    console.print(" " ++ msg ++ "\n", .{});
}

fn printBanner() void {
    console.print("\n\n", .{});
    console.printColored("  =========================================\n", .{}, .cyan, .black);
    console.printColored("  Welcome to ", .{}, .white, .black);
    console.printColored("sobOS", .{}, .light_green, .black);
    console.printColored(" by pfaria-d and evmorvan\n", .{}, .white, .black);
    console.printColored("  =========================================\n", .{}, .cyan, .black);
    console.print("\n", .{});
}

fn printBootInfo() void {
    printStatus("GDT initialized");
    printStatus("IDT initialized");
    printStatus("PIC configured");
    if (keyboard.isInitialized()) {
        printStatus("Keyboard IRQ handler registered");
    } else {
        console.printColored("  [", .{}, .white, .black);
        console.printColored("FAIL", .{}, .red, .black);
        console.printColored("]", .{}, .white, .black);
        console.print(" Keyboard IRQ handler NOT registered\n", .{});
    }
    console.print("\n", .{});
}

// ============================================================================
// Kernel Main
// ============================================================================

noinline fn kmain() callconv(.c) noreturn {
    // Initialize architecture (GDT, IDT, PIC)
    initArch();

    // Initialize drivers
    initDrivers();

    // Display boot info
    printBanner();
    printBootInfo();

    // Prompt
    console.printColored("  > ", .{}, .light_green, .black);

    // Enable interrupts
    idt.enableInterrupts();

    // Main loop: hlt until interrupt, then check for input
    while (true) {
        asm volatile ("hlt");
        while (keyboard.getChar()) |char| {
            console.printChar(char);
        }
    }
}
