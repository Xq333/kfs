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

var g_row: usize = 0;
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
    var i: usize = 0;
    while (i < vga.SIZE) : (i += 1) {
        g_buffer[i] = blank_char;
    }
    g_row = 0;
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
    const lines_to_move = vga.HEIGHT - 1;
    const copy_size = lines_to_move * vga.WIDTH;
    var i: usize = 0;
    while (i < copy_size) : (i += 1) {
        g_buffer[i] = g_buffer[i + vga.WIDTH];
    }

    const last_line_start = lines_to_move * vga.WIDTH;
    const blank_char = Color.getVgaChar(g_color, ' ');
    i = last_line_start;
    while (i < vga.SIZE) : (i += 1) {
        g_buffer[i] = blank_char;
    }

    g_row = lines_to_move;
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
