// Header Bar
// Persistent status bar at top of screen showing current screen info

const vga = @import("../drivers/vga.zig");
const buffer = @import("buffer.zig");
const screen = @import("screen.zig");

// Screen names for the header
pub const screen_names = [screen.SCREEN_COUNT][]const u8{
    "F1: System",
    "F2: Terminal",
    "F3: Stack",
    "F4: Help",
    "F5: About",
};

// Header colors
const HEADER_BG = buffer.ColorType.blue;
const HEADER_FG = buffer.ColorType.white;
const ACTIVE_FG = buffer.ColorType.yellow;

/// Draw the header bar at row 0
pub fn draw() void {
    const vga_buffer = @as([*]volatile u16, @ptrFromInt(vga.BUFFER_ADDR));
    const header_color = buffer.Color.init(HEADER_FG, HEADER_BG);
    const active_color = buffer.Color.init(ACTIVE_FG, HEADER_BG);

    // Fill entire first row with background
    for (0..vga.WIDTH) |x| {
        vga_buffer[x] = header_color.getVgaChar(' ');
    }

    // Draw "sobOS" on the left
    const title = " sobOS ";
    for (title, 0..) |char, i| {
        vga_buffer[i] = active_color.getVgaChar(char);
    }

    // Draw separator
    vga_buffer[title.len] = header_color.getVgaChar('|');

    // Draw all screen tabs
    var pos: usize = title.len + 1;
    const active = screen.getActiveScreen();

    for (screen_names, 0..) |name, i| {
        // Add space before tab
        vga_buffer[pos] = header_color.getVgaChar(' ');
        pos += 1;

        // Choose color based on active screen
        const tab_color = if (i == active) active_color else header_color;

        // Draw screen name
        for (name) |char| {
            if (pos < vga.WIDTH) {
                vga_buffer[pos] = tab_color.getVgaChar(char);
                pos += 1;
            }
        }

        // Add space after tab
        if (pos < vga.WIDTH) {
            vga_buffer[pos] = header_color.getVgaChar(' ');
            pos += 1;
        }

        // Add separator (except after last)
        if (i < screen_names.len - 1 and pos < vga.WIDTH) {
            vga_buffer[pos] = header_color.getVgaChar('|');
            pos += 1;
        }
    }
}

/// Get the name of a screen by index
pub fn getScreenName(index: usize) []const u8 {
    if (index < screen_names.len) {
        return screen_names[index];
    }
    return "Unknown";
}
