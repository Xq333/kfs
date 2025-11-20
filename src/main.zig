const std = @import("std");
const multiboot = @import("multiboot.zig");

export fn _start() callconv(.Naked) noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
