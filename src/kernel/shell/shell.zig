// Minimalistic Shell for debugging
// Commands: help, clear, stack, reboot, halt, echo, gdt, time

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

    // Parse command and arguments
    const parsed = parseCommand(cmd);

    if (strEql(parsed.cmd, "help")) {
        cmdHelp();
    } else if (strEql(parsed.cmd, "clear")) {
        cmdClear();
    } else if (strEql(parsed.cmd, "stack")) {
        cmdStack();
    } else if (strEql(parsed.cmd, "reboot")) {
        cmdReboot();
    } else if (strEql(parsed.cmd, "halt")) {
        cmdHalt();
    } else if (strEql(parsed.cmd, "echo")) {
        cmdEcho(parsed.args);
    } else if (strEql(parsed.cmd, "gdt")) {
        cmdGdt();
    } else if (strEql(parsed.cmd, "info")) {
        cmdInfo();
    } else if (strEql(parsed.cmd, "sdump")) {
        cmdStackDump();
    } else if (parsed.cmd.len > 0) {
        console.printColored("  Unknown command: ", .{}, .light_red, .black);
        printStr(parsed.cmd);
        console.print("\n", .{});
        console.printColored("  Type 'help' for available commands.\n", .{}, .dark_gray, .black);
    }
}

const ParsedCommand = struct {
    cmd: []const u8,
    args: []const u8,
};

fn parseCommand(input: []const u8) ParsedCommand {
    // Skip leading spaces
    var start: usize = 0;
    while (start < input.len and input[start] == ' ') : (start += 1) {}

    // Find end of command (first space or end)
    var end: usize = start;
    while (end < input.len and input[end] != ' ') : (end += 1) {}

    const cmd = if (start < end) input[start..end] else input[0..0];

    // Skip spaces after command
    var args_start: usize = end;
    while (args_start < input.len and input[args_start] == ' ') : (args_start += 1) {}

    const args = if (args_start < input.len) input[args_start..] else input[0..0];

    return .{ .cmd = cmd, .args = args };
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

fn cmdStackDump() void {
    console.print("\n", .{});
    console.printColored("  Kernel Stack Dump:\n", .{}, .yellow, .black);

    // Get current frame address as ESP estimate
    const esp: u32 = @truncate(@frameAddress());

    const stack_bottom = kstack.stackBottomAddr();
    const stack_top = kstack.stackTopAddr();

    console.print("  ESP:  0x", .{});
    printHex32(esp);
    console.print("\n", .{});
    console.print("  Top:  0x", .{});
    printHex32(stack_top);
    console.print("\n", .{});
    console.print("  Bot:  0x", .{});
    printHex32(stack_bottom);
    console.print("\n\n", .{});

    // Dump stack memory with paging
    console.printColored("  Offset   Address     Value      ASCII\n", .{}, .cyan, .black);
    console.print("  ------------------------------------------\n", .{});

    var offset: u32 = 0;
    var lines: u32 = 0;
    const lines_per_page: u32 = 14; // Lines before prompting

    while (esp +% offset < stack_top) {
        const addr = esp +% offset;

        // Print offset
        console.print("  +", .{});
        printHex8(@truncate(offset));
        console.print("    0x", .{});
        printHex32(addr);
        console.print("  ", .{});

        // Read and print value
        const ptr: *const u32 = @ptrFromInt(addr);
        const val = ptr.*;
        printHex32(val);
        console.print("   |", .{});

        // ASCII for 4 bytes
        const b0: u8 = @truncate(val);
        const b1: u8 = @truncate(val >> 8);
        const b2: u8 = @truncate(val >> 16);
        const b3: u8 = @truncate(val >> 24);

        printAsciiChar(b0);
        printAsciiChar(b1);
        printAsciiChar(b2);
        printAsciiChar(b3);
        console.print("|\n", .{});

        offset += 4;
        lines += 1;

        // Pager: pause every N lines
        if (lines >= lines_per_page and esp +% offset < stack_top) {
            console.printColored("  -- Press SPACE for more, Q to quit --", .{}, .dark_gray, .black);
            const key = waitForKey();
            // Clear the prompt line
            console.print("\r                                        \r", .{});
            if (key == 'q' or key == 'Q') {
                console.print("\n", .{});
                return;
            }
            lines = 0;
        }
    }

    console.printColored("  -- End of stack --\n", .{}, .dark_gray, .black);
    console.print("\n", .{});
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
