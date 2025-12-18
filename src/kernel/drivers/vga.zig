// VGA hardware constants and low-level I/O operations

pub const WIDTH = 80;
pub const HEIGHT = 25;
pub const SIZE = WIDTH * HEIGHT;

// VGA hardware cursor I/O ports
const VGA_CTRL_REGISTER = 0x3D4;
const VGA_DATA_REGISTER = 0x3D5;
const VGA_CURSOR_HIGH = 0x0E;
const VGA_CURSOR_LOW = 0x0F;

// VGA text mode buffer address
pub const BUFFER_ADDR = 0xB8000;

/// Output byte to I/O port
pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port),
    );
}

/// Input byte from I/O port
pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

/// Update hardware cursor position
pub fn updateCursor(row: usize, column: usize) void {
    const pos: u16 = @intCast(row * WIDTH + column);

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
}

/// Disable hardware cursor
pub fn disableCursor() void {
    outb(VGA_CTRL_REGISTER, 0x0A);
    outb(VGA_DATA_REGISTER, 0x20);
}

