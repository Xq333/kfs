// Kernel stack definition and helpers

pub const STACK_SIZE: usize = 16 * 1024;

pub var stack_bytes: [STACK_SIZE]u8 align(16) linksection(".bss") = undefined;

/// Top of stack address as u32 (stack grows down, so this is the high address)
pub fn stackTopAddr() u32 {
    return @intFromPtr(&stack_bytes) + STACK_SIZE;
}

/// Bottom of stack address as u32 (low address)
pub fn stackBottomAddr() u32 {
    return @intFromPtr(&stack_bytes);
}
