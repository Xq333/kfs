// Stack Viewer (F3)
// Displays kernel stack information in a human-friendly way
// Uses direct VGA writes to avoid heavy formatting machinery

const kstack = @import("../arch/stack.zig");

const VGA_CYAN: u8 = 0x0B;
const VGA_YELLOW: u8 = 0x0E;
const VGA_GRAY: u8 = 0x07;
const VGA_DARK_GRAY: u8 = 0x08;
const VGA_GREEN: u8 = 0x0A;

const VGA_BUFFER: u32 = 0xB8000;
const HEX_CHARS = "0123456789ABCDEF";

pub fn draw() void {
    const vga_ptr: [*]volatile u16 = @ptrFromInt(VGA_BUFFER);

    // Clear screen (except header row 0)
    var i: u32 = 80;
    while (i < 2000) : (i += 1) {
        vga_ptr[i] = (@as(u16, VGA_GRAY) << 8) | ' ';
    }

    // Get stack registers
    var esp: u32 = undefined;
    var ebp: u32 = undefined;
    asm volatile ("mov %%esp, %[esp]"
        : [esp] "=r" (esp),
    );
    asm volatile ("mov %%ebp, %[ebp]"
        : [ebp] "=r" (ebp),
    );

    // Row 2: Title
    writeStringAt(vga_ptr, 2, 2, "=== KERNEL STACK VIEWER ===", VGA_CYAN);

    // Row 4: Registers
    writeStringAt(vga_ptr, 4, 2, "Registers:", VGA_YELLOW);
    writeStringAt(vga_ptr, 5, 4, "ESP: 0x", VGA_GRAY);
    writeHex32At(vga_ptr, 5, 11, esp, VGA_GREEN);
    writeStringAt(vga_ptr, 6, 4, "EBP: 0x", VGA_GRAY);
    writeHex32At(vga_ptr, 6, 11, ebp, VGA_GREEN);

    // Row 8: Stack Memory Dump (8 dwords from ESP)
    writeStringAt(vga_ptr, 8, 2, "Stack Dump (from ESP):", VGA_YELLOW);

    // Read 8 dwords from stack
    var row: u32 = 9;
    var offset: u32 = 0;
    while (offset < 32 and row < 17) : (offset += 4) {
        const addr = esp +% offset;
        writeStringAt(vga_ptr, row, 4, "+", VGA_DARK_GRAY);
        writeHex8At(vga_ptr, row, 5, @truncate(offset), VGA_DARK_GRAY);
        writeStringAt(vga_ptr, row, 7, ": 0x", VGA_GRAY);

        // Read dword from stack
        const ptr: *const u32 = @ptrFromInt(addr);
        const val = ptr.*;
        writeHex32At(vga_ptr, row, 11, val, VGA_GREEN);

        row += 1;
    }

    // Right column: Call Stack (EBP chain)
    writeStringAt(vga_ptr, 4, 42, "Call Stack:", VGA_YELLOW);

    var frame_row: u32 = 5;
    var frame_ebp = ebp;
    var frame_num: u32 = 0;

    while (frame_ebp != 0 and frame_num < 10 and frame_row < 16) {
        // Read saved EBP and return address
        const saved_ebp_ptr: *const u32 = @ptrFromInt(frame_ebp);
        const ret_addr_ptr: *const u32 = @ptrFromInt(frame_ebp +% 4);

        const saved_ebp = saved_ebp_ptr.*;
        const ret_addr = ret_addr_ptr.*;

        // Write frame number
        writeStringAt(vga_ptr, frame_row, 42, "#", VGA_DARK_GRAY);
        _ = writeHexNibble(vga_ptr, frame_row, 43, @truncate(frame_num), VGA_DARK_GRAY);
        writeStringAt(vga_ptr, frame_row, 44, " RET=0x", VGA_GRAY);
        writeHex32At(vga_ptr, frame_row, 51, ret_addr, VGA_GREEN);

        frame_ebp = saved_ebp;
        frame_num += 1;
        frame_row += 1;

        // Stop if we hit a null or invalid frame
        if (saved_ebp == 0 or saved_ebp < 0x100000) break;
    }

    if (frame_num == 0) {
        writeStringAt(vga_ptr, 5, 44, "(no frames)", VGA_DARK_GRAY);
    }

    // Right column: Stack Bounds (below call stack)
    const stack_bottom = kstack.stackBottomAddr();
    const stack_top = kstack.stackTopAddr();
    const stack_used = if (stack_top > esp) stack_top - esp else 0;

    writeStringAt(vga_ptr, 17, 42, "Stack Bounds:", VGA_YELLOW);
    writeStringAt(vga_ptr, 18, 44, "Bot: 0x", VGA_GRAY);
    writeHex32At(vga_ptr, 18, 51, stack_bottom, VGA_GREEN);
    writeStringAt(vga_ptr, 19, 44, "Top: 0x", VGA_GRAY);
    writeHex32At(vga_ptr, 19, 51, stack_top, VGA_GREEN);
    writeStringAt(vga_ptr, 20, 44, "Used:", VGA_GRAY);
    writeDecAt(vga_ptr, 20, 50, stack_used, VGA_GREEN);
    writeStringAt(vga_ptr, 20, 56, "/ 16384", VGA_DARK_GRAY);

    // Row 22: GDT summary
    writeStringAt(vga_ptr, 22, 2, "GDT: 7 entries at 0x00000800", VGA_GRAY);

    // Footer
    writeStringAt(vga_ptr, 24, 2, "Press F1-F5 to switch screens", VGA_DARK_GRAY);
}

fn writeStringAt(vga_ptr: [*]volatile u16, row: u32, col: u32, s: []const u8, color: u8) void {
    var c: u32 = col;
    for (s) |ch| {
        if (c >= 80) break;
        const pos = row * 80 + c;
        if (pos < 2000) {
            vga_ptr[pos] = (@as(u16, color) << 8) | ch;
        }
        c += 1;
    }
}

fn writeHex32At(vga_ptr: [*]volatile u16, row: u32, col: u32, value: u32, color: u8) void {
    var c: u32 = col;
    // Write 8 hex digits
    c = writeHexNibble(vga_ptr, row, c, @truncate(value >> 28), color);
    c = writeHexNibble(vga_ptr, row, c, @truncate(value >> 24), color);
    c = writeHexNibble(vga_ptr, row, c, @truncate(value >> 20), color);
    c = writeHexNibble(vga_ptr, row, c, @truncate(value >> 16), color);
    c = writeHexNibble(vga_ptr, row, c, @truncate(value >> 12), color);
    c = writeHexNibble(vga_ptr, row, c, @truncate(value >> 8), color);
    c = writeHexNibble(vga_ptr, row, c, @truncate(value >> 4), color);
    _ = writeHexNibble(vga_ptr, row, c, @truncate(value), color);
}

fn writeHexNibble(vga_ptr: [*]volatile u16, row: u32, col: u32, nibble: u4, color: u8) u32 {
    const pos = row * 80 + col;
    if (pos < 2000) {
        vga_ptr[pos] = (@as(u16, color) << 8) | HEX_CHARS[nibble];
    }
    return col + 1;
}

fn writeHex8At(vga_ptr: [*]volatile u16, row: u32, col: u32, value: u8, color: u8) void {
    var c: u32 = col;
    c = writeHexNibble(vga_ptr, row, c, @truncate(value >> 4), color);
    _ = writeHexNibble(vga_ptr, row, c, @truncate(value), color);
}

fn writeDecAt(vga_ptr: [*]volatile u16, row: u32, col: u32, value: u32, color: u8) void {
    if (value == 0) {
        const pos = row * 80 + col;
        if (pos < 2000) {
            vga_ptr[pos] = (@as(u16, color) << 8) | '0';
        }
        return;
    }

    // Convert to decimal - write digits right to left, then reverse
    var buf: [6]u8 = [_]u8{ ' ', ' ', ' ', ' ', ' ', ' ' };
    var v = value;
    var i: usize = 5;

    while (v > 0) {
        buf[i] = '0' + @as(u8, @truncate(v % 10));
        v /= 10;
        if (i == 0) break;
        i -= 1;
    }

    // Find first non-space and write from there
    var start: usize = 0;
    while (start < 6 and buf[start] == ' ') : (start += 1) {}

    var c: u32 = col;
    while (start < 6) : (start += 1) {
        const pos = row * 80 + c;
        if (pos < 2000) {
            vga_ptr[pos] = (@as(u16, color) << 8) | buf[start];
        }
        c += 1;
    }
}
