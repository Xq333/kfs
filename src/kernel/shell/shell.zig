const console = @import("../io/console.zig");
const kstack = @import("../arch/stack.zig");
const gdt = @import("../arch/gdt.zig");
const keyboard = @import("../drivers/keyboard.zig");

const MAX_CMD_LEN: usize = 64;

var cmd_buffer: [MAX_CMD_LEN]u8 = undefined;
var cmd_len: usize = 0;

/// Initialize shell state
pub fn init() void {
    cmd_len = 0;
}

/// Add a character to the command buffer
pub fn addChar(char: u8) void {
    if (cmd_len < MAX_CMD_LEN - 1) {
        cmd_buffer[cmd_len] = char;
        cmd_len += 1;
    }
}

/// Remove last character (backspace)
pub fn removeChar() void {
    if (cmd_len > 0) {
        cmd_len -= 1;
    }
}

/// Execute the current command
pub fn execute() void {
    if (cmd_len == 0) {
        return;
    }

    const cmd = cmd_buffer[0..cmd_len];
    cmd_len = 0;

    // Parse command and arguments (uses globals to avoid struct return issues)
    parseCommand(cmd);

    if (strEql(g_parsed_cmd, "help")) {
        cmdHelp();
    } else if (strEql(g_parsed_cmd, "clear")) {
        cmdClear();
    } else if (strEql(g_parsed_cmd, "stack")) {
        cmdStack();
    } else if (strEql(g_parsed_cmd, "reboot")) {
        cmdReboot();
    } else if (strEql(g_parsed_cmd, "halt")) {
        cmdHalt();
    } else if (strEql(g_parsed_cmd, "echo")) {
        cmdEcho(g_parsed_args);
    } else if (strEql(g_parsed_cmd, "gdt")) {
        cmdGdt();
    } else if (strEql(g_parsed_cmd, "info")) {
        cmdInfo();
    } else if (strEql(g_parsed_cmd, "sdump")) {
        cmdStackDump();
    } else if (g_parsed_cmd.len > 0) {
        console.printColored("  Unknown command: ", .{}, .light_red, .black);
        printStr(g_parsed_cmd);
        console.print("\n", .{});
        console.printColored("  Type 'help' for available commands.\n", .{}, .dark_gray, .black);
    }
}

// Global parsed command storage (avoids struct return issues on some QEMU versions)
var g_parsed_cmd: []const u8 = &[_]u8{};
var g_parsed_args: []const u8 = &[_]u8{};

fn parseCommand(input: []const u8) void {
    // Skip leading spaces
    var start: usize = 0;
    while (start < input.len and input[start] == ' ') : (start += 1) {}

    // Find end of command (first space or end)
    var end: usize = start;
    while (end < input.len and input[end] != ' ') : (end += 1) {}

    g_parsed_cmd = if (start < end) input[start..end] else input[0..0];

    // Skip spaces after command
    var args_start: usize = end;
    while (args_start < input.len and input[args_start] == ' ') : (args_start += 1) {}

    g_parsed_args = if (args_start < input.len) input[args_start..] else input[0..0];
}

// ============================================================================
// Commands
// ============================================================================

fn cmdHelp() void {
    console.print("\n", .{});
    console.printColored("  Available commands:\n", .{}, .yellow, .black);
    console.print("    help   - Show this help message\n", .{});
    console.print("    clear  - Clear the terminal screen\n", .{});
    console.print("    stack  - Print kernel stack information\n", .{});
    console.print("    sdump  - Dump entire kernel stack memory\n", .{});
    console.print("    gdt    - Show GDT information\n", .{});
    console.print("    info   - Show system information\n", .{});
    console.print("    echo   - Echo text back\n", .{});
    console.print("    reboot - Reboot the system\n", .{});
    console.print("    halt   - Halt the CPU\n", .{});
    console.print("\n", .{});
}

fn cmdClear() void {
    console.clear();
    console.printColored("  Terminal\n", .{}, .cyan, .black);
    console.printColored("  --------\n\n", .{}, .cyan, .black);
}

fn cmdStack() void {
    console.print("\n", .{});
    console.printColored("  Kernel Stack:\n", .{}, .yellow, .black);

    // Get frame address (returns usize in Zig 0.15)
    const frame_addr: u32 = @truncate(@frameAddress());

    console.print("    Frame: 0x", .{});
    printHex32(frame_addr);
    console.print("\n", .{});
    console.print("    Stack size: ", .{});
    printDec(kstack.STACK_SIZE);
    console.print(" bytes\n", .{});
    console.print("\n", .{});
    console.printColored("  (See F3 for detailed stack view)\n", .{}, .dark_gray, .black);
    console.print("\n", .{});
}

fn cmdGdt() void {
    console.print("\n", .{});
    console.printColored("  GDT Information:\n", .{}, .yellow, .black);
    console.print("    Address: 0x", .{});
    printHex32(gdt.gdtBaseAddr());
    console.print("\n", .{});
    console.print("    Entries: ", .{});
    printDec(gdt.GDT_SIZE);
    console.print("\n", .{});
    console.print("\n", .{});
    console.printColored("  Segments:\n", .{}, .yellow, .black);
    console.print("    0x00 - Null descriptor\n", .{});
    console.print("    0x08 - Kernel Code (ring 0)\n", .{});
    console.print("    0x10 - Kernel Data (ring 0)\n", .{});
    console.print("    0x18 - Kernel Stack (ring 0)\n", .{});
    console.print("    0x20 - User Code (ring 3)\n", .{});
    console.print("    0x28 - User Data (ring 3)\n", .{});
    console.print("    0x30 - User Stack (ring 3)\n", .{});
    console.print("\n", .{});
}

fn cmdInfo() void {
    console.print("\n", .{});
    console.printColored("  System Information:\n", .{}, .yellow, .black);
    console.print("    OS:      sobOS\n", .{});
    console.print("    Arch:    i386 (x86)\n", .{});
    console.print("    Stack:   16 KB\n", .{});
    console.print("    Video:   VGA 80x25\n", .{});
    console.print("    Screens: 5 (F1-F5)\n", .{});
    console.print("\n", .{});
}

// Static buffer to avoid stack allocation in sdump
var sdump_ascii_buf: [16]u8 = undefined;

fn cmdStackDump() void {
    console.printChar('\n');
    console.printColored("  Kernel Stack Dump:\n", .{}, .yellow, .black);

    // Get current ESP via inline assembly
    var esp: u32 = undefined;
    asm volatile ("mov %%esp, %[esp]"
        : [esp] "=r" (esp),
    );

    const stack_bottom = kstack.stackBottomAddr();
    const stack_top = kstack.stackTopAddr();

    console.printString("  ESP:  0x");
    printHex32(esp);
    console.printChar('\n');
    console.printString("  Top:  0x");
    printHex32(stack_top);
    console.printChar('\n');
    console.printString("  Bot:  0x");
    printHex32(stack_bottom);
    console.printString("\n\n");

    // Dump with 16 bytes per row
    console.printColored("  Address     +0       +4       +8       +C         ASCII\n", .{}, .cyan, .black);
    console.printString("  -------------------------------------------------------------------\n");

    var addr: u32 = esp;
    var lines: u32 = 0;
    const lines_per_page: u32 = 16;

    while (addr < stack_top) {
        console.printString("  0x");
        printHex32(addr);

        // Read 4 dwords and store bytes for ASCII
        var byte_count: usize = 0;

        // Column 0
        if (addr < stack_top) {
            const ptr: *const volatile u32 = @ptrFromInt(addr);
            const val = ptr.*;
            console.printString("  ");
            printHex32(val);
            sdump_ascii_buf[0] = @truncate(val);
            sdump_ascii_buf[1] = @truncate(val >> 8);
            sdump_ascii_buf[2] = @truncate(val >> 16);
            sdump_ascii_buf[3] = @truncate(val >> 24);
            byte_count = 4;
        }

        // Column 1
        if (addr +% 4 < stack_top) {
            const ptr: *const volatile u32 = @ptrFromInt(addr +% 4);
            const val = ptr.*;
            console.printChar(' ');
            printHex32(val);
            sdump_ascii_buf[4] = @truncate(val);
            sdump_ascii_buf[5] = @truncate(val >> 8);
            sdump_ascii_buf[6] = @truncate(val >> 16);
            sdump_ascii_buf[7] = @truncate(val >> 24);
            byte_count = 8;
        } else {
            console.printString("          ");
        }

        // Column 2
        if (addr +% 8 < stack_top) {
            const ptr: *const volatile u32 = @ptrFromInt(addr +% 8);
            const val = ptr.*;
            console.printChar(' ');
            printHex32(val);
            sdump_ascii_buf[8] = @truncate(val);
            sdump_ascii_buf[9] = @truncate(val >> 8);
            sdump_ascii_buf[10] = @truncate(val >> 16);
            sdump_ascii_buf[11] = @truncate(val >> 24);
            byte_count = 12;
        } else {
            console.printString("          ");
        }

        // Column 3
        if (addr +% 12 < stack_top) {
            const ptr: *const volatile u32 = @ptrFromInt(addr +% 12);
            const val = ptr.*;
            console.printChar(' ');
            printHex32(val);
            sdump_ascii_buf[12] = @truncate(val);
            sdump_ascii_buf[13] = @truncate(val >> 8);
            sdump_ascii_buf[14] = @truncate(val >> 16);
            sdump_ascii_buf[15] = @truncate(val >> 24);
            byte_count = 16;
        } else {
            console.printString("          ");
        }

        // Print ASCII
        console.printString("  |");
        var i: usize = 0;
        while (i < byte_count) : (i += 1) {
            printAsciiChar(sdump_ascii_buf[i]);
        }
        while (i < 16) : (i += 1) {
            console.printChar(' ');
        }
        console.printString("|\n");

        addr +%= 16;
        lines += 1;

        // Pager
        if (lines >= lines_per_page and addr < stack_top) {
            console.printColored("  -- Press SPACE for more, Q to quit --", .{}, .dark_gray, .black);
            const key = waitForKey();
            console.printString("\r                                        \r");
            if (key == 'q' or key == 'Q') {
                console.printChar('\n');
                return;
            }
            lines = 0;
        }
    }

    console.printColored("  -- End of stack --\n", .{}, .dark_gray, .black);
    console.printChar('\n');
}

/// Wait for a keypress (blocking)
fn waitForKey() u8 {
    // Clear any pending input
    while (keyboard.getChar()) |_| {}

    // Wait for new input
    while (true) {
        if (keyboard.getChar()) |c| {
            return c;
        }
        // Halt until next interrupt
        asm volatile ("hlt");
    }
}

fn printAsciiChar(b: u8) void {
    if (b >= 0x20 and b < 0x7F) {
        console.printChar(b);
    } else {
        console.printChar('.');
    }
}

fn cmdEcho(args: []const u8) void {
    console.print("  ", .{});
    printStr(args);
    console.print("\n", .{});
}

fn cmdReboot() void {
    console.print("\n", .{});
    console.printColored("  Rebooting...\n", .{}, .yellow, .black);

    // Method: Pulse CPU reset line via keyboard controller
    // Wait for keyboard controller to be ready, then send reset command

    // Disable interrupts first
    asm volatile ("cli");

    // Wait for keyboard controller input buffer to be empty
    var timeout: u32 = 100000;
    while (timeout > 0) : (timeout -= 1) {
        const status = asm volatile ("inb $0x64, %[ret]"
            : [ret] "={al}" (-> u8),
        );
        if ((status & 0x02) == 0) break;
    }

    // Send reset command (0xFE) to keyboard controller
    asm volatile ("outb %[val], $0x64"
        :
        : [val] "{al}" (@as(u8, 0xFE)),
    );

    // If that didn't work, try triple fault
    var i: u32 = 100000;
    while (i > 0) : (i -= 1) {
        asm volatile ("nop");
    }

    // Triple fault as fallback
    asm volatile ("lidt %[null_idt]"
        :
        : [null_idt] "m" (@as(u48, 0)),
    );
    asm volatile ("int $0x03");

    unreachable;
}

fn cmdHalt() void {
    console.print("\n", .{});
    console.printColored("  Shutting down...\n", .{}, .yellow, .black);

    // Disable interrupts
    asm volatile ("cli");

    // QEMU shutdown via debug port (isa-debug-exit or ACPI)
    // Port 0x604 with value 0x2000 triggers ACPI shutdown in QEMU
    asm volatile ("outw %[val], %[port]"
        :
        : [val] "{ax}" (@as(u16, 0x2000)),
          [port] "N{dx}" (@as(u16, 0x604)),
    );

    // Bochs/older QEMU shutdown
    asm volatile ("outw %[val], %[port]"
        :
        : [val] "{ax}" (@as(u16, 0x2000)),
          [port] "N{dx}" (@as(u16, 0xB004)),
    );

    // If ACPI didn't work, just halt
    console.printColored("  System halted (ACPI unavailable).\n", .{}, .dark_gray, .black);
    console.printColored("  Close QEMU window to exit.\n", .{}, .dark_gray, .black);

    while (true) {
        asm volatile ("hlt");
    }
}

// ============================================================================
// Helpers
// ============================================================================

fn strEql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |ca, cb| {
        if (ca != cb) return false;
    }
    return true;
}

fn printStr(s: []const u8) void {
    for (s) |c| {
        console.printChar(c);
    }
}

const HEX_CHARS = "0123456789ABCDEF";

fn printHex32(value: u32) void {
    printHexNibble(@truncate(value >> 28));
    printHexNibble(@truncate(value >> 24));
    printHexNibble(@truncate(value >> 20));
    printHexNibble(@truncate(value >> 16));
    printHexNibble(@truncate(value >> 12));
    printHexNibble(@truncate(value >> 8));
    printHexNibble(@truncate(value >> 4));
    printHexNibble(@truncate(value));
}

fn printHex8(value: u8) void {
    printHexNibble(@truncate(value >> 4));
    printHexNibble(@truncate(value));
}

fn printHexNibble(nibble: u4) void {
    console.printChar(HEX_CHARS[nibble]);
}

fn printDec(value: usize) void {
    if (value == 0) {
        console.printChar('0');
        return;
    }
    // Find the highest power of 10 <= value
    var divisor: usize = 1;
    var temp = value;
    while (temp >= 10) {
        divisor *= 10;
        temp /= 10;
    }
    // Print digits from most significant to least
    var v = value;
    while (divisor > 0) {
        const digit: u8 = @truncate(v / divisor);
        console.printChar('0' + digit);
        v = v % divisor;
        if (divisor == 1) break;
        divisor /= 10;
    }
}
