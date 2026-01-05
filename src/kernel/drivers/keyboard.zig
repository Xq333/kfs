// PS/2 Keyboard Driver
// Handles keyboard input via polling and scancode translation

const vga = @import("vga.zig");

// ============================================================================
// Constants
// ============================================================================

const DATA_PORT: u16 = 0x60;
const STATUS_PORT: u16 = 0x64;
const OUTPUT_BUFFER_FULL: u8 = 0x01;

// Special scancodes
const SC_LEFT_SHIFT: u8 = 0x2A;
const SC_RIGHT_SHIFT: u8 = 0x36;
const SC_CAPS_LOCK: u8 = 0x3A;
const SC_LEFT_CTRL: u8 = 0x1D;

// ============================================================================
// Scancode Tables (US QWERTY - Set 1)
// ============================================================================

// prettier-ignore
const scancode_table = [_]u8{
    0, 0x1B, '1', '2', '3', '4', '5', '6', // 0x00-0x07
    '7', '8', '9', '0', '-', '=', '\x08', '\t', // 0x08-0x0F
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', // 0x10-0x17
    'o', 'p', '[', ']', '\n', 0, 'a', 's', // 0x18-0x1F
    'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', // 0x20-0x27
    '\'', '`', 0, '\\', 'z', 'x', 'c', 'v', // 0x28-0x2F
    'b', 'n', 'm', ',', '.', '/', 0, '*', // 0x30-0x37
    0, ' ', 0, 0, 0, 0, 0, 0, // 0x38-0x3F
    0, 0, 0, 0, 0, 0, 0, 0, // 0x40-0x47
    0, 0, 0, 0, 0, 0, 0, 0, // 0x48-0x4F
    0, 0, 0, 0, 0, 0, 0, 0, // 0x50-0x57
    0, 0, 0, 0, 0, 0, 0, 0, // 0x58-0x5F
};

// prettier-ignore
const scancode_table_shifted = [_]u8{
    0, 0x1B, '!', '@', '#', '$', '%', '^', // 0x00-0x07
    '&', '*', '(', ')', '_', '+', '\x08', '\t', // 0x08-0x0F
    'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', // 0x10-0x17
    'O', 'P', '{', '}', '\n', 0, 'A', 'S', // 0x18-0x1F
    'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', // 0x20-0x27
    '"', '~', 0, '|', 'Z', 'X', 'C', 'V', // 0x28-0x2F
    'B', 'N', 'M', '<', '>', '?', 0, '*', // 0x30-0x37
    0, ' ', 0, 0, 0, 0, 0, 0, // 0x38-0x3F
    0, 0, 0, 0, 0, 0, 0, 0, // 0x40-0x47
    0, 0, 0, 0, 0, 0, 0, 0, // 0x48-0x4F
    0, 0, 0, 0, 0, 0, 0, 0, // 0x50-0x57
    0, 0, 0, 0, 0, 0, 0, 0, // 0x58-0x5F
};

// ============================================================================
// State
// ============================================================================

var shift_pressed: bool = false;
var caps_lock: bool = false;
var ctrl_pressed: bool = false;

// ============================================================================
// Public API
// ============================================================================

/// Initialize keyboard driver
pub fn init() void {
    // Flush any pending scancodes in the buffer
    while ((vga.inb(STATUS_PORT) & OUTPUT_BUFFER_FULL) != 0) {
        _ = vga.inb(DATA_PORT);
    }
}

/// Poll keyboard and return character if available (non-blocking)
pub fn getChar() ?u8 {
    if ((vga.inb(STATUS_PORT) & OUTPUT_BUFFER_FULL) == 0) {
        return null;
    }
    return processScancode(vga.inb(DATA_PORT));
}

/// Check modifier states
pub fn isCtrlPressed() bool {
    return ctrl_pressed;
}

pub fn isShiftPressed() bool {
    return shift_pressed;
}

pub fn isCapsLockActive() bool {
    return caps_lock;
}

// ============================================================================
// Internal
// ============================================================================

fn processScancode(scancode: u8) ?u8 {
    // Key release (bit 7 set)
    if (scancode & 0x80 != 0) {
        return handleKeyRelease(scancode & 0x7F);
    }
    return handleKeyPress(scancode);
}

fn handleKeyRelease(code: u8) ?u8 {
    switch (code) {
        SC_LEFT_SHIFT, SC_RIGHT_SHIFT => shift_pressed = false,
        SC_LEFT_CTRL => ctrl_pressed = false,
        else => {},
    }
    return null;
}

fn handleKeyPress(scancode: u8) ?u8 {
    // Handle modifier keys
    switch (scancode) {
        SC_LEFT_SHIFT, SC_RIGHT_SHIFT => {
            shift_pressed = true;
            return null;
        },
        SC_CAPS_LOCK => {
            caps_lock = !caps_lock;
            return null;
        },
        SC_LEFT_CTRL => {
            ctrl_pressed = true;
            return null;
        },
        else => {},
    }

    // Convert to ASCII
    if (scancode >= scancode_table.len) {
        return null;
    }

    const char = if (shift_pressed != caps_lock)
        scancode_table_shifted[scancode]
    else
        scancode_table[scancode];

    return if (char != 0) char else null;
}
