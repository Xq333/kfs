// Terminal Screen (F2)
// Interactive shell interface

const console = @import("../io/console.zig");

pub fn draw() void {
    console.clear();
    console.printColored("  Terminal\n", .{}, .cyan, .black);
    console.printColored("  --------\n\n", .{}, .cyan, .black);
    printPrompt();
}

pub fn printPrompt() void {
    console.printColored("  > ", .{}, .light_green, .black);
}
