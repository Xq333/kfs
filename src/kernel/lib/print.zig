// Kernel printing and logging utilities
// Provides printf/printk-style functions for easy debugging and information display

const console = @import("../io/console.zig");

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

pub fn debug(comptime fmt: []const u8, args: anytype) void {
    logInternal("[DEBUG] ", LEVEL_COLORS.debug, fmt, args);
}

pub fn info(comptime fmt: []const u8, args: anytype) void {
    logInternal("[INFO]  ", LEVEL_COLORS.info, fmt, args);
}

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    logInternal("[WARN]  ", LEVEL_COLORS.warn, fmt, args);
}

pub fn err(comptime fmt: []const u8, args: anytype) void {
    logInternal("[ERROR] ", LEVEL_COLORS.err, fmt, args);
}

pub fn printc(comptime fmt: []const u8, args: anytype, fg: console.ColorType, bg: console.ColorType) void {
    console.printColored(fmt, args, fg, bg);
}

pub fn puts(str: []const u8) void {
    console.printString(str);
}

pub fn putsln(str: []const u8) void {
    console.printString(str);
    console.print("\n", .{});
}
