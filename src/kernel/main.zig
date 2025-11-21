const std = @import("std");
const multiboot = @import("multiboot.zig");
const console = @import("console.zig");

var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

// We specify that this function is "naked" to let the compiler know
// not to generate a standard function prologue* and epilogue*s, since
// we don't have a stack yet.

// Prologue: saves the caller’s base pointer (push ebp), sets the callee’s base pointer (mov ebp, esp), reserves stack space for locals (sub esp, ...), maybe saves callee-saved registers.
// Epilogue: restores the stack and registers (mov esp, ebp, pop ebp), then returns (ret).

export fn _start() callconv(.naked) noreturn {
    // We use inline assembly to set up the stack before jumping to
    // our kernel entry point.
    asm volatile (
        \\ movl %[stack_top], %%esp
        \\ movl %%esp, %%ebp
        \\ call %[kmain:P]
        :
        // The stack grows downwards on x86, so we need to point ESP register
        // to one element past the end of `stack_bytes`.
        //
        // Unfortunately, we can't just compute `&stack_bytes[stack_bytes.len]`,
        // as the Zig compiler will notice the out-of-bounds access at
        // compile-time and throw an error. We can instead take the start address
        // of `stack_bytes` then convert into "multi-pointers" `[*]` where zig
        // allows pointer arithmetic and get the &stack_bytes[stack_bytes.len]
        //
        // Finally, we pass the whole expression as an input operand with the
        // "immediate" constraint to force the compiler to encode this as an
        // absolute address. This prevents the compiler from doing unnecessary
        // extra steps to compute the address at runtime (especially in Debug mode),
        // which could possibly clobber registers that are specified by multiboot
        // to hold special values (e.g. EAX).
        : [stack_top] "i" (&@as([*]align(16) u8, @ptrCast(&stack_bytes))[stack_bytes.len]),
          // We let the compiler handle the reference to kmain by passing it as an input operand as well.
          [kmain] "X" (&kmain),
    );
}

fn kmain() void {
    console.init();
    console.print("Hello {s} kernel!", .{"zig"});
    while (true) {
        asm volatile ("hlt");
    }
}
