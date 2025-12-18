// Console API - High-level interface for text output
// Provides formatted printing and color support

const std = @import("std");
const buffer = @import("buffer.zig");

// Re-export ColorType for convenience
pub const ColorType = buffer.ColorType;

pub fn init() void {
    buffer.init();
}

pub fn setColor(fg: ColorType, bg: ColorType) void {
    buffer.setColor(fg, bg);
}

pub fn clear() void {
    buffer.clear();
}

pub fn printChar(char: u8) void {
    buffer.writeChar(char);
}

pub fn printString(str: []const u8) void {
    buffer.writeString(str);
}

pub fn printCharAt(char: u8, fg: ColorType, bg: ColorType, x: usize, y: usize) void {
    const color = buffer.Color.init(fg, bg);
    buffer.writeCharAt(char, color, x, y);
}

pub fn printColored(comptime fmt: []const u8, args: anytype, fg: ColorType, bg: ColorType) void {
    const old_fg = buffer.getFg();
    const old_bg = buffer.getBg();
    setColor(fg, bg);
    print(fmt, args);
    setColor(old_fg, old_bg);
}

/// Implementation of std.Io.Writer.vtable.drain function
fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) !usize {
    std.debug.assert(data.len != 0);

    var consumed: usize = 0;
    const pattern = data[data.len - 1];
    const splat_len = pattern.len * splat;

    if (w.end != 0) {
        printString(w.buffered());
        w.end = 0;
    }

    for (data[0 .. data.len - 1]) |bytes| {
        printString(bytes);
        consumed += bytes.len;
    }

    switch (pattern.len) {
        0 => {},
        else => {
            for (0..splat) |_| {
                printString(pattern);
            }
        },
    }
    consumed += splat_len;
    return consumed;
}

pub fn writer(writer_buffer: []u8) std.Io.Writer {
    return .{
        .buffer = writer_buffer,
        .end = 0,
        .vtable = &.{
            .drain = drain,
        },
    };
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    var w = writer(&.{});
    w.print(fmt, args) catch return;
}
