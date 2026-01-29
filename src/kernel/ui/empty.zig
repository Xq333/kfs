// Empty Screen (F3)
// Placeholder for future features

const console = @import("../io/console.zig");

pub fn draw() void {
    console.clear();
    console.print("\n\n\n", .{});
    console.printColored("                    There's no F3 yet.\n", .{}, .dark_gray, .black);
}
