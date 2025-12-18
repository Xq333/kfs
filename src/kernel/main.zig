const std = @import("std");
const console = @import("io/console.zig");
const print = @import("lib/print.zig");
const keyboard = @import("drivers/keyboard.zig");

const MB_HEADER_MAGIC = 0x1BADB002;
const MB_FLAG_ALIGN = 1 << 0;
const MB_FLAG_MEMINFO = 1 << 1;
const FLAGS = MB_FLAG_ALIGN | MB_FLAG_MEMINFO;

/// https://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Header-layout
const MultibootHeader = packed struct {
    magic: u32 = MB_HEADER_MAGIC,
    flags: u32 = FLAGS,
    checksum: u32,
    padding: u32 = 0,
};

export var multiboot: MultibootHeader align(4) linksection(".multiboot") = .{
    // Here we are adding magic and flags and ~ to get 1's complement and by adding 1 we get 2's complement
    .checksum = ~@as(u32, (MB_HEADER_MAGIC + FLAGS)) + 1,
};

var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

// We specify that this function is "naked" to let the compiler know
// not to generate a standard function prologue and epilogue, since
// we don't have a stack yet.
export fn _start() callconv(.naked) noreturn {
    // We use inline assembly to set up the stack before jumping to
    // our kernel entry point.
    asm volatile (
        \\ movl %[stack_top], %%esp
        \\ movl %%esp, %%ebp
        \\ call %[kmain:P]
        :
        : [stack_top] "i" (&@as([*]align(16) u8, @ptrCast(&stack_bytes))[stack_bytes.len]),
          [kmain] "X" (&kmain),
    );
}

fn helloWorld() noreturn {}

// We use noinline to make sure it doesn't get inlined by compiler
noinline fn kmain() callconv(.c) noreturn {
    console.init();

    console.print("\n\n", .{});

    // Title with cyan color
    console.printColored("  =========================================\n", .{}, .cyan, .black);
    console.printColored("  Welcome to ", .{}, .white, .black);
    console.printColored("sobOS", .{}, .light_green, .black);
    console.printColored(" by pfaria-d and evmorvan\n", .{}, .white, .black);
    console.printColored("  =========================================\n", .{}, .cyan, .black);

    console.print("\n", .{});

    // System info with different colors
    console.printColored("  [", .{}, .white, .black);
    console.printColored("OK", .{}, .green, .black);
    console.printColored("]", .{}, .white, .black);
    console.print(" Kernel initialized\n", .{});

    console.printColored("  [", .{}, .white, .black);
    console.printColored("OK", .{}, .green, .black);
    console.printColored("]", .{}, .white, .black);
    console.print(" VGA text mode active\n", .{});

    console.printColored("  [", .{}, .white, .black);
    console.printColored("OK", .{}, .green, .black);
    console.printColored("]", .{}, .white, .black);
    console.print(" Multiboot loaded successfully\n", .{});

    console.print("\n", .{});
    console.printColored("  Status: ", .{}, .yellow, .black);
    console.printColored("System is idle and halted\n", .{}, .light_gray, .black);
    console.print("\n", .{});

    // Color demonstration
    console.printColored("  Color Demo: ", .{}, .white, .black);
    console.printColored("Red ", .{}, .red, .black);
    console.printColored("Green ", .{}, .green, .black);
    console.printColored("Blue ", .{}, .blue, .black);
    console.printColored("Yellow ", .{}, .yellow, .black);
    console.printColored("Magenta ", .{}, .magenta, .black);
    console.printColored("Cyan", .{}, .cyan, .black);
    console.print("\n\n", .{});

    // Scroll test - print many lines to demonstrate scrolling
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);
    console.printColored("  Scroll Test:\n", .{}, .yellow, .black);

    while (true) {
        asm volatile ("hlt");
    }
}
