// Screen Manager
// Handles multiple virtual screens (terminals) with F1-F5 switching

const vga = @import("../drivers/vga.zig");
const buffer = @import("buffer.zig");
const header = @import("header.zig");

pub const SCREEN_COUNT: usize = 5;

// Each screen stores: buffer content, cursor position, color
const Screen = struct {
    data: [vga.SIZE]u16,
    row: usize,
    column: usize,
    color: buffer.Color,
};

var screens: [SCREEN_COUNT]Screen = undefined;
var active_screen: usize = 0;
var initialized: bool = false;

/// Initialize all screens with blank content
pub fn init() void {
    const blank = buffer.Color.init(.light_gray, .black).getVgaChar(' ');

    for (&screens) |*s| {
        for (&s.data) |*cell| {
            cell.* = blank;
        }
        s.row = 1; // Start below header
        s.column = 0;
        s.color = buffer.Color.init(.light_gray, .black);
    }

    active_screen = 0;
    initialized = true;
}

/// Switch to a different screen (0-4 for F1-F5)
pub fn switchTo(screen_num: usize) void {
    if (screen_num >= SCREEN_COUNT) return;
    if (screen_num == active_screen) return;
    if (!initialized) return;

    // Save current VGA buffer and cursor to old screen
    saveCurrentScreen();

    // Switch active screen
    active_screen = screen_num;

    // Load new screen to VGA buffer
    loadCurrentScreen();
}

/// Save VGA buffer content to current screen
fn saveCurrentScreen() void {
    const vga_buffer = @as([*]volatile u16, @ptrFromInt(vga.BUFFER_ADDR));

    // Save buffer content
    for (0..vga.SIZE) |i| {
        screens[active_screen].data[i] = vga_buffer[i];
    }

    // Save cursor position and color
    screens[active_screen].row = buffer.getRow();
    screens[active_screen].column = buffer.getColumn();
    screens[active_screen].color = buffer.getColor();
}

/// Load current screen to VGA buffer
fn loadCurrentScreen() void {
    const vga_buffer = @as([*]volatile u16, @ptrFromInt(vga.BUFFER_ADDR));

    // Restore buffer content
    for (0..vga.SIZE) |i| {
        vga_buffer[i] = screens[active_screen].data[i];
    }

    // Restore cursor position and color
    buffer.setPosition(screens[active_screen].row, screens[active_screen].column);
    buffer.setColor(
        @enumFromInt(screens[active_screen].color.fg),
        @enumFromInt(screens[active_screen].color.bg),
    );

    // Redraw header to show active screen
    header.draw();
}

/// Get current active screen number (0-indexed)
pub fn getActiveScreen() usize {
    return active_screen;
}

/// Get active screen number for display (1-indexed)
pub fn getActiveScreenDisplay() usize {
    return active_screen + 1;
}
