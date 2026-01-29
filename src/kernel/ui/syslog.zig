// System Logger
// Logs boot messages to the System screen (F1) in real-time

const console = @import("../io/console.zig");
const screen = @import("../io/screen.zig");

/// Log a status message with [OK] prefix
pub fn ok(comptime msg: []const u8) void {
    const current = screen.getActiveScreen();
    if (current != 0) screen.switchTo(0);

    console.printColored("  [", .{}, .white, .black);
    console.printColored("OK", .{}, .green, .black);
    console.printColored("]", .{}, .white, .black);
    console.print(" " ++ msg ++ "\n", .{});

    if (current != 0) screen.switchTo(current);
}

/// Log a failure message with [FAIL] prefix
pub fn fail(comptime msg: []const u8) void {
    const current = screen.getActiveScreen();
    if (current != 0) screen.switchTo(0);

    console.printColored("  [", .{}, .white, .black);
    console.printColored("FAIL", .{}, .red, .black);
    console.printColored("]", .{}, .white, .black);
    console.print(" " ++ msg ++ "\n", .{});

    if (current != 0) screen.switchTo(current);
}

/// Log a section header
pub fn section(comptime title: []const u8) void {
    const current = screen.getActiveScreen();
    if (current != 0) screen.switchTo(0);

    console.printColored("  " ++ title ++ "\n", .{}, .yellow, .black);

    if (current != 0) screen.switchTo(current);
}

/// Log an info message
pub fn info(comptime fmt: []const u8, args: anytype) void {
    const current = screen.getActiveScreen();
    if (current != 0) screen.switchTo(0);

    console.printColored("  ", .{}, .light_green, .black);
    console.printColored(fmt ++ "\n", args, .light_green, .black);

    if (current != 0) screen.switchTo(current);
}

/// Add blank line
pub fn newline() void {
    const current = screen.getActiveScreen();
    if (current != 0) screen.switchTo(0);

    console.print("\n", .{});

    if (current != 0) screen.switchTo(current);
}
