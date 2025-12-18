// Kernel printing and logging utilities
// Provides printf/printk-style functions for easy debugging and information display

const console = @import("console.zig");

/// Log levels with associated colors
pub const LogLevel = enum {
    debug,
    info,
    warn,
    err,
};

const LEVEL_COLORS = .{
    .debug = console.ColorType.cyan,
    .info = console.ColorType.white,
    .warn = console.ColorType.yellow,
    .err = console.ColorType.red,
};

/// Kernel print - equivalent to printf
/// Usage: printk("Value: {}\n", .{42})
pub fn printk(comptime fmt: []const u8, args: anytype) void {
    console.print(fmt, args);
}

/// Printf alias for printk
pub const printf = printk;

/// Print with log level prefix and color
fn logInternal(comptime prefix: []const u8, color: console.ColorType, comptime fmt: []const u8, args: anytype) void {
    console.printColored(prefix, .{}, color, .black);
    console.print(fmt, args);
}

/// Debug log
pub fn debug(comptime fmt: []const u8, args: anytype) void {
    logInternal("[DEBUG] ", LEVEL_COLORS.debug, fmt, args);
}

/// Info log
pub fn info(comptime fmt: []const u8, args: anytype) void {
    logInternal("[INFO]  ", LEVEL_COLORS.info, fmt, args);
}

/// Warning log
pub fn warn(comptime fmt: []const u8, args: anytype) void {
    logInternal("[WARN]  ", LEVEL_COLORS.warn, fmt, args);
}

/// Error log
pub fn err(comptime fmt: []const u8, args: anytype) void {
    logInternal("[ERROR] ", LEVEL_COLORS.err, fmt, args);
}

/// Print formatted string with color
pub fn printc(comptime fmt: []const u8, args: anytype, fg: console.ColorType, bg: console.ColorType) void {
    console.printColored(fmt, args, fg, bg);
}

/// Print string (no formatting)
pub fn puts(str: []const u8) void {
    console.printString(str);
}

/// Print string with newline
pub fn putsln(str: []const u8) void {
    console.printString(str);
    console.print("\n", .{});
}
