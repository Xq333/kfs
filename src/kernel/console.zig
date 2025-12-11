const std = @import("std");

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

// VGA hardware cursor I/O ports
const VGA_CTRL_REGISTER = 0x3D4;
const VGA_DATA_REGISTER = 0x3D5;
const VGA_CURSOR_HIGH = 0x0E;
const VGA_CURSOR_LOW = 0x0F;

var g_row: usize = 0;
var g_column: usize = 0;
var g_color: Color = .init(.light_gray, .black);
var g_buffer = @as([*]volatile u16, @ptrFromInt(0xB8000));

pub const ColorType = enum(u4) {
    black = 0,
    blue = 1,
    green = 2,
    cyan = 3,
    red = 4,
    magenta = 5,
    brown = 6,
    light_gray = 7,
    dark_gray = 8,
    light_blue = 9,
    light_green = 10,
    light_cyan = 11,
    light_red = 12,
    light_magenta = 13,
    light_brown = 14,
    white = 15,
};

const Color = packed struct(u8) {
    fg: ColorType,
    bg: ColorType,

    pub fn init(fg: ColorType, bg: ColorType) Color {
        return .{ .fg = fg, .bg = bg };
    }

    /// Combine vga color and char. The upper byte will be color and lower byte will be character
    pub fn getVgaChar(self: Color, char: u8) u16 {
        return @as(u16, @as(u8, @bitCast(self))) << 8 | char;
    }
};

/// Initialize VGA
pub fn init() void {
    clear();
    enableCursor();
    updateCursor();
}

/// Update hardware cursor position
fn updateCursor() void {
    const pos: u16 = @intCast(g_row * VGA_WIDTH + g_column);

    // Send high byte
    outb(VGA_CTRL_REGISTER, VGA_CURSOR_HIGH);
    outb(VGA_DATA_REGISTER, @intCast((pos >> 8) & 0xFF));

    // Send low byte
    outb(VGA_CTRL_REGISTER, VGA_CURSOR_LOW);
    outb(VGA_DATA_REGISTER, @intCast(pos & 0xFF));
}

/// Enable hardware cursor
pub fn enableCursor() void {
    outb(VGA_CTRL_REGISTER, 0x0A);
    const cursor_start = inb(VGA_DATA_REGISTER) & 0xC0;
    outb(VGA_DATA_REGISTER, cursor_start | 0); // Cursor start line

    outb(VGA_CTRL_REGISTER, 0x0B);
    const cursor_end = inb(VGA_DATA_REGISTER) & 0xE0;
    outb(VGA_DATA_REGISTER, cursor_end | 15); // Cursor end line

    updateCursor();
}

/// Disable hardware cursor
pub fn disableCursor() void {
    outb(VGA_CTRL_REGISTER, 0x0A);
    outb(VGA_DATA_REGISTER, 0x20);
}

/// Output byte to I/O port
inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port),
    );
}

/// Input byte from I/O port
inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

/// Set Color for VGA
pub fn setColor(fg: ColorType, bg: ColorType) void {
    g_color = Color.init(fg, bg);
}

/// Print with color
pub fn printColored(comptime fmt: []const u8, args: anytype, fg: ColorType, bg: ColorType) void {
    const old_color = g_color;
    setColor(fg, bg);
    print(fmt, args);
    g_color = old_color;
}

/// Print string with color
pub fn printStringColored(str: []const u8, fg: ColorType, bg: ColorType) void {
    const old_color = g_color;
    setColor(fg, bg);
    printString(str);
    g_color = old_color;
}

/// Clear the screen
pub fn clear() void {
    @memset(g_buffer[0..VGA_SIZE], Color.getVgaChar(g_color, ' '));
    g_row = 0;
    g_column = 0;
    updateCursor();
}

/// Print character with color at specific position
pub fn printCharAt(char: u8, color: Color, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    g_buffer[index] = color.getVgaChar(char);
}

/// Scroll the screen up by one line
fn scroll() void {
    // Move all lines up by one
    var i: usize = 0;
    while (i < (VGA_HEIGHT - 1) * VGA_WIDTH) : (i += 1) {
        g_buffer[i] = g_buffer[i + VGA_WIDTH];
    }

    // Clear the last line
    const last_line_start = (VGA_HEIGHT - 1) * VGA_WIDTH;
    i = 0;
    while (i < VGA_WIDTH) : (i += 1) {
        g_buffer[last_line_start + i] = Color.getVgaChar(g_color, ' ');
    }

    // Reset row back to last line
    g_row = VGA_HEIGHT - 1;
}

/// Check if scrolling is needed and scroll if necessary
fn checkAndScroll() void {
    if (g_row >= VGA_HEIGHT) {
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
            var i: usize = 0;
            while (i < spaces) : (i += 1) {
                printChar(' ');
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
            if (g_column >= VGA_WIDTH) {
                g_column = 0;
                g_row += 1;
                checkAndScroll();
            } else {
                updateCursor();
            }
        },
    }
}

/// Implementation of std.Io.Writer.vtable.drain function.
/// When flush is called or the writer buffer is full this function is called.
/// This function first writes all data of writer buffer after that it writes
/// the argument data in which the last element is written splat times.
fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) !usize {
    // the length of data must not be zero
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

    // If out patter (i.e. last element of data) is non zero len then write splat times
    switch (pattern.len) {
        0 => {},
        else => {
            for (0..splat) |_| {
                printString(pattern);
            }
        },
    }
    // Now we have to return how many bytes we consumed from data
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

/// Print string to VGA
pub fn printString(str: []const u8) void {
    for (str) |char| {
        printChar(char);
    }
}

/// Print with standard zig format to VGA
pub fn print(comptime fmt: []const u8, args: anytype) void {
    var w = writer(&.{});
    w.print(fmt, args) catch return;
}
