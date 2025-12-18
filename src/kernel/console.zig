const std = @import("std");
const colors = @import("colors.zig");
const vga = @import("vga.zig");

var g_row: usize = 0;
var g_column: usize = 0;
var g_color: Color = .init(.light_gray, .black);
var g_buffer = @as([*]volatile u16, @ptrFromInt(vga.BUFFER_ADDR));

// Re-export Color from colors module for convenience
pub const ColorType = colors.Color;

const Color = packed struct(u8) {
    fg: u4,
    bg: u4,

    pub fn init(fg: ColorType, bg: ColorType) Color {
        return .{
            .fg = @intCast(@intFromEnum(fg) & 0x0F),
            .bg = @intCast(@intFromEnum(bg) & 0x0F),
        };
    }

    /// Combine vga color and char. The upper byte will be color and lower byte will be character
    pub inline fn getVgaChar(self: Color, char: u8) u16 {
        return @as(u16, @as(u8, @bitCast(self))) << 8 | char;
    }
};

/// Initialize VGA
pub fn init() void {
    clear();
    vga.enableCursor();
    updateCursor();
}

/// Update hardware cursor position
fn updateCursor() void {
    vga.updateCursor(g_row, g_column);
}

/// Set Color for VGA
pub fn setColor(fg: ColorType, bg: ColorType) void {
    g_color = Color.init(fg, bg);
}

/// Clear the screen
pub fn clear() void {
    const blank_char = Color.getVgaChar(g_color, ' ');
    var i: usize = 0;
    while (i < vga.SIZE) : (i += 1) {
        g_buffer[i] = blank_char;
    }
    g_row = 0;
    g_column = 0;
    updateCursor();
}

/// Print character with color at specific position
pub fn printCharAt(char: u8, color: Color, x: usize, y: usize) void {
    const index = y * vga.WIDTH + x;
    g_buffer[index] = color.getVgaChar(char);
}

/// Scroll the screen up by one line
fn scroll() void {
    // Move all lines up by one
    const lines_to_move = vga.HEIGHT - 1;
    const copy_size = lines_to_move * vga.WIDTH;
    var i: usize = 0;
    while (i < copy_size) : (i += 1) {
        g_buffer[i] = g_buffer[i + vga.WIDTH];
    }

    // Clear the last line
    const last_line_start = lines_to_move * vga.WIDTH;
    const blank_char = Color.getVgaChar(g_color, ' ');
    i = last_line_start;
    while (i < vga.SIZE) : (i += 1) {
        g_buffer[i] = blank_char;
    }

    // Reset row back to last line
    g_row = lines_to_move;
}

/// Check if scrolling is needed and scroll if necessary
fn checkAndScroll() void {
    if (g_row >= vga.HEIGHT) {
        scroll();
    }
    updateCursor();
}

/// Print character to the VGA
pub fn printChar(char: u8) void {
    switch (char) {
        '\n' => {
            g_column = 0;
            g_row += 1;
            checkAndScroll();
        },
        '\r' => {
            g_column = 0;
            updateCursor();
        },
        '\t' => {
            // Tab stops at every 4 characters
            const tab_width = 4;
            const spaces = tab_width - (g_column % tab_width);
            const space_char = Color.getVgaChar(g_color, ' ');
            var i: usize = 0;
            while (i < spaces) : (i += 1) {
                if (g_column >= vga.WIDTH) break;
                g_buffer[g_row * vga.WIDTH + g_column] = space_char;
                g_column += 1;
            }
            if (g_column >= vga.WIDTH) {
                g_column = 0;
                g_row += 1;
                checkAndScroll();
            } else {
                updateCursor();
            }
        },
        '\x08' => { // Backspace
            if (g_column > 0) {
                g_column -= 1;
                printCharAt(' ', g_color, g_column, g_row);
                updateCursor();
            }
        },
        else => {
            printCharAt(char, g_color, g_column, g_row);
            g_column += 1;
            if (g_column >= vga.WIDTH) {
                g_column = 0;
                g_row += 1;
                checkAndScroll();
            } else {
                updateCursor();
            }
        },
    }
}

/// Print string to VGA
pub fn printString(str: []const u8) void {
    for (str) |char| {
        printChar(char);
    }
}

/// Print with color
pub fn printColored(comptime fmt: []const u8, args: anytype, fg: ColorType, bg: ColorType) void {
    const old_color = g_color;
    setColor(fg, bg);
    print(fmt, args);
    g_color = old_color;
}

/// Implementation of std.Io.Writer.vtable.drain function.
/// When flush is called or the writer buffer is full this function is called.
/// This function first writes all data of writer buffer after that it writes
/// the argument data in which the last element is written splat times.
fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) !usize {
    std.debug.assert(data.len != 0);

    var consumed: usize = 0;
    const pattern = data[data.len - 1];
    const splat_len = pattern.len * splat;

    // If buffer is not empty write it first
    if (w.end != 0) {
        printString(w.buffered());
        w.end = 0;
    }

    // Now write all data except last element
    for (data[0 .. data.len - 1]) |bytes| {
        printString(bytes);
        consumed += bytes.len;
    }

    // If pattern (i.e. last element of data) is non zero len then write splat times
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

/// Returns std.Io.Writer implementation for this console
pub fn writer(buffer: []u8) std.Io.Writer {
    return .{
        .buffer = buffer,
        .end = 0,
        .vtable = &.{
            .drain = drain,
        },
    };
}

/// Print with standard zig format to VGA
pub fn print(comptime fmt: []const u8, args: anytype) void {
    var w = writer(&.{});
    w.print(fmt, args) catch return;
}
