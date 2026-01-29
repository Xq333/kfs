// Help Screen (F4)
// Shows keyboard shortcuts and usage info

const console = @import("../io/console.zig");

pub fn draw() void {
    console.clear();
    console.printColored("  Help\n", .{}, .cyan, .black);
    console.printColored("  ----\n\n", .{}, .cyan, .black);

    console.print("  Keyboard Shortcuts:\n\n", .{});

    console.printColored("    F1", .{}, .yellow, .black);
    console.print(" - System info (boot log)\n", .{});

    console.printColored("    F2", .{}, .yellow, .black);
    console.print(" - Terminal (interactive shell)\n", .{});

    console.printColored("    F3", .{}, .yellow, .black);
    console.print(" - Kernel Stack Viewer\n", .{});

    console.printColored("    F4", .{}, .yellow, .black);
    console.print(" - This help screen\n", .{});

    console.printColored("    F5", .{}, .yellow, .black);
    console.print(" - About sobOS\n", .{});

    console.print("\n  Shell Commands (F2):\n\n", .{});

    console.printColored("    help", .{}, .light_green, .black);
    console.print("   - Show available commands\n", .{});

    console.printColored("    clear", .{}, .light_green, .black);
    console.print("  - Clear terminal screen\n", .{});

    console.printColored("    stack", .{}, .light_green, .black);
    console.print("  - Print kernel stack info\n", .{});

    console.printColored("    gdt", .{}, .light_green, .black);
    console.print("    - Show GDT segments\n", .{});

    console.printColored("    info", .{}, .light_green, .black);
    console.print("   - System information\n", .{});

    console.printColored("    echo", .{}, .light_green, .black);
    console.print("   - Echo text back\n", .{});

    console.printColored("    reboot", .{}, .light_green, .black);
    console.print(" - Reboot the system\n", .{});

    console.printColored("    halt", .{}, .light_green, .black);
    console.print("   - Halt the CPU\n", .{});
}
