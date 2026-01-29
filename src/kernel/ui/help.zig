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
    console.print(" - (not implemented yet)\n", .{});

    console.printColored("    F4", .{}, .yellow, .black);
    console.print(" - This help screen\n", .{});

    console.printColored("    F5", .{}, .yellow, .black);
    console.print(" - About sobOS\n", .{});

    console.print("\n  Note: Keyboard input only works on F2 (Terminal).\n", .{});

    console.print("\n  Terminal Keys:\n\n", .{});
    console.printColored("    Enter", .{}, .yellow, .black);
    console.print("     - New line\n", .{});
    console.printColored("    Backspace", .{}, .yellow, .black);
    console.print(" - Delete character\n", .{});
    console.printColored("    Shift", .{}, .yellow, .black);
    console.print("     - Uppercase / symbols\n", .{});
    console.printColored("    Caps Lock", .{}, .yellow, .black);
    console.print(" - Toggle caps\n", .{});
}
