// About Screen (F5)
// Shows information about sobOS

const console = @import("../io/console.zig");

pub fn draw() void {
    console.clear();
    console.printColored("  About sobOS\n", .{}, .cyan, .black);
    console.printColored("  -----------\n\n", .{}, .cyan, .black);

    console.print("  A minimal x86 kernel written in Zig.\n\n", .{});

    console.print("  Authors:\n", .{});
    console.printColored("    - pfaria-d\n", .{}, .light_green, .black);
    console.printColored("    - evmorvan\n", .{}, .light_green, .black);

    console.print("\n  Built with:\n", .{});
    console.print("    - Zig programming language\n", .{});
    console.print("    - GRUB bootloader\n", .{});
    console.print("    - x86 protected mode\n", .{});

    console.print("\n  Features:\n", .{});
    console.print("    - Interrupt-driven keyboard\n", .{});
    console.print("    - VGA text mode display\n", .{});
    console.print("    - 5 virtual screens\n", .{});
    console.print("    - Real-time boot logging\n", .{});
}
