// VGA text buffer management
// Handles low-level buffer operations, cursor, and scrolling

const colors = @import("../lib/colors.zig");
const vga = @import("../drivers/vga.zig");

pub const ColorType = colors.Color;

pub const Color = packed struct(u8) {
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

// Header takes row 0, content starts at row 1
const CONTENT_START_ROW: usize = 1;
const CONTENT_HEIGHT: usize = vga.HEIGHT - CONTENT_START_ROW;

var g_row: usize = CONTENT_START_ROW;
var g_column: usize = 0;
var g_color: Color = .init(.light_gray, .black);
var g_buffer = @as([*]volatile u16, @ptrFromInt(vga.BUFFER_ADDR));

pub fn init() void {
    clear();
    vga.enableCursor();
    updateCursor();
}

pub fn getRow() usize {
    return g_row;
}

pub fn getColumn() usize {
    return g_column;
}

pub fn setPosition(row: usize, column: usize) void {
    g_row = row;
    g_column = column;
    updateCursor();
}

pub fn setColor(fg: ColorType, bg: ColorType) void {
    g_color = Color.init(fg, bg);
}

pub fn getColor() Color {
    return g_color;
}

pub fn getFg() ColorType {
    return @enumFromInt(g_color.fg);
}

pub fn getBg() ColorType {
    return @enumFromInt(g_color.bg);
}

pub fn clear() void {
    const blank_char = Color.getVgaChar(g_color, ' ');
    // Only clear content area (row 1 onwards), leave header (row 0) intact
    var i: usize = CONTENT_START_ROW * vga.WIDTH;
    while (i < vga.SIZE) : (i += 1) {
        g_buffer[i] = blank_char;
    }
    g_row = CONTENT_START_ROW;
    g_column = 0;
    updateCursor();
}

fn updateCursor() void {
    vga.updateCursor(g_row, g_column);
}

pub fn writeCharAt(char: u8, color: Color, x: usize, y: usize) void {
    const index = y * vga.WIDTH + x;
    g_buffer[index] = color.getVgaChar(char);
}

fn scroll() void {
    // Only scroll content area (rows 1-24), leave header (row 0) intact
    const content_start = CONTENT_START_ROW * vga.WIDTH;
    const lines_to_move = CONTENT_HEIGHT - 1;
    const copy_size = lines_to_move * vga.WIDTH;

    // Move lines up within content area
    var i: usize = 0;
    while (i < copy_size) : (i += 1) {
        g_buffer[content_start + i] = g_buffer[content_start + i + vga.WIDTH];
    }

    // Clear last line
    const last_line_start = (vga.HEIGHT - 1) * vga.WIDTH;
    const blank_char = Color.getVgaChar(g_color, ' ');
    i = last_line_start;
    while (i < vga.SIZE) : (i += 1) {
        g_buffer[i] = blank_char;
    }

    g_row = vga.HEIGHT - 1;
}

fn checkAndScroll() void {
    if (g_row >= vga.HEIGHT) {
        scroll();
    }
    updateCursor();
}

pub fn writeChar(char: u8) void {
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
                writeCharAt(' ', g_color, g_column, g_row);
                updateCursor();
            }
        },
        else => {
            writeCharAt(char, g_color, g_column, g_row);
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

pub fn writeString(str: []const u8) void {
    for (str) |char| {
        writeChar(char);
    }
}
