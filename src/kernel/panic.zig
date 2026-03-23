// Kernel Panic Handler
// Handles unrecoverable errors

const std = @import("std");
const console = @import("io/console.zig");

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = error_return_trace;
    _ = ret_addr;

    // Force enable interrupts? No, better to disable.
    asm volatile ("cli");

    // Try to print broadly
    console.printColored("\n\n!!! KERNEL PANIC !!!\n", .{}, .white, .red);
    console.printColored("{s}\n", .{msg}, .white, .red);
    console.printColored("System Halted.\n", .{}, .white, .red);

    while (true) {
        asm volatile ("hlt");
    }
}
