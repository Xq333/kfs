// Kernel stack definition and helpers

pub const STACK_SIZE: usize = 16 * 1024;

pub var stack_bytes: [STACK_SIZE]u8 align(16) linksection(".bss") = undefined;

/// Pointer to the top of the kernel stack (grows down)
pub fn stackTopPtr() *align(16) u8 {
    return &@as([*]align(16) u8, @ptrCast(&stack_bytes))[STACK_SIZE];
}

/// Pointer to the bottom of the kernel stack
pub fn stackBottomPtr() *align(16) u8 {
    return @ptrCast(&stack_bytes);
}

/// Top of stack address as u32
pub fn stackTopAddr() u32 {
    return @intFromPtr(stackTopPtr());
}

/// Bottom of stack address as u32
pub fn stackBottomAddr() u32 {
    return @intFromPtr(stackBottomPtr());
}
