// Interrupt Service Routines (ISR)
// Low-level interrupt handlers

const pic = @import("pic.zig");

// ============================================================================
// Interrupt Handler Callback
// ============================================================================

pub var irq_handlers: [16]?*const fn (u8) void = [_]?*const fn (u8) void{null} ** 16;

pub fn registerIrqHandler(irq: u8, handler: *const fn (u8) void) void {
    irq_handlers[irq] = handler;
}

// ============================================================================
// Common Handler (called from assembly stubs)
// ============================================================================

export fn isrHandler(int_no: u32) callconv(.c) void {
    // Exception handlers (0-31) - just halt for now
    _ = int_no;
    asm volatile ("cli");
    while (true) {
        asm volatile ("hlt");
    }
}

export fn irqHandler(irq_no: u32) callconv(.c) void {
    // Call registered handler if any
    if (irq_no < 16) {
        if (irq_handlers[irq_no]) |handler| {
            handler(@truncate(irq_no));
        }
    }

    // Send EOI
    pic.sendEOI(@truncate(irq_no));
}

// ============================================================================
// Exception Stubs (ISR 0-31)
// ============================================================================

pub fn isr0() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $0
        \\ jmp isrCommon
    );
}

pub fn isr1() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $1
        \\ jmp isrCommon
    );
}

pub fn isr2() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $2
        \\ jmp isrCommon
    );
}

pub fn isr3() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $3
        \\ jmp isrCommon
    );
}

pub fn isr4() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $4
        \\ jmp isrCommon
    );
}

pub fn isr5() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $5
        \\ jmp isrCommon
    );
}

pub fn isr6() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $6
        \\ jmp isrCommon
    );
}

pub fn isr7() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $7
        \\ jmp isrCommon
    );
}

pub fn isr8() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $8
        \\ jmp isrCommon
    );
}

pub fn isr9() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $9
        \\ jmp isrCommon
    );
}

pub fn isr10() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $10
        \\ jmp isrCommon
    );
}

pub fn isr11() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $11
        \\ jmp isrCommon
    );
}

pub fn isr12() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $12
        \\ jmp isrCommon
    );
}

pub fn isr13() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $13
        \\ jmp isrCommon
    );
}

pub fn isr14() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $14
        \\ jmp isrCommon
    );
}

pub fn isr15() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $15
        \\ jmp isrCommon
    );
}

pub fn isr16() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $16
        \\ jmp isrCommon
    );
}

pub fn isr17() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $17
        \\ jmp isrCommon
    );
}

pub fn isr18() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $18
        \\ jmp isrCommon
    );
}

pub fn isr19() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $19
        \\ jmp isrCommon
    );
}

pub fn isr20() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $20
        \\ jmp isrCommon
    );
}

pub fn isr21() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $21
        \\ jmp isrCommon
    );
}

pub fn isr22() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $22
        \\ jmp isrCommon
    );
}

pub fn isr23() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $23
        \\ jmp isrCommon
    );
}

pub fn isr24() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $24
        \\ jmp isrCommon
    );
}

pub fn isr25() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $25
        \\ jmp isrCommon
    );
}

pub fn isr26() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $26
        \\ jmp isrCommon
    );
}

pub fn isr27() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $27
        \\ jmp isrCommon
    );
}

pub fn isr28() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $28
        \\ jmp isrCommon
    );
}

pub fn isr29() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $29
        \\ jmp isrCommon
    );
}

pub fn isr30() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $30
        \\ jmp isrCommon
    );
}

pub fn isr31() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $31
        \\ jmp isrCommon
    );
}

// ============================================================================
// IRQ Stubs (IRQ 0-15 -> INT 32-47)
// ============================================================================

pub fn irq0() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $0
        \\ jmp irqCommon
    );
}

pub fn irq1() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $1
        \\ jmp irqCommon
    );
}

pub fn irq2() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $2
        \\ jmp irqCommon
    );
}

pub fn irq3() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $3
        \\ jmp irqCommon
    );
}

pub fn irq4() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $4
        \\ jmp irqCommon
    );
}

pub fn irq5() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $5
        \\ jmp irqCommon
    );
}

pub fn irq6() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $6
        \\ jmp irqCommon
    );
}

pub fn irq7() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $7
        \\ jmp irqCommon
    );
}

pub fn irq8() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $8
        \\ jmp irqCommon
    );
}

pub fn irq9() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $9
        \\ jmp irqCommon
    );
}

pub fn irq10() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $10
        \\ jmp irqCommon
    );
}

pub fn irq11() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $11
        \\ jmp irqCommon
    );
}

pub fn irq12() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $12
        \\ jmp irqCommon
    );
}

pub fn irq13() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $13
        \\ jmp irqCommon
    );
}

pub fn irq14() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $14
        \\ jmp irqCommon
    );
}

pub fn irq15() callconv(.naked) void {
    asm volatile (
        \\ cli
        \\ push $0
        \\ push $15
        \\ jmp irqCommon
    );
}

// ============================================================================
// Common Stubs
// ============================================================================

export fn isrCommon() callconv(.naked) void {
    asm volatile (
        \\ pusha
        \\ mov %%esp, %%eax
        \\ push %%eax
        \\ mov 32(%%esp), %%eax
        \\ push %%eax
        \\ call isrHandler
        \\ add $8, %%esp
        \\ popa
        \\ add $8, %%esp
        \\ iret
    );
}

export fn irqCommon() callconv(.naked) void {
    asm volatile (
        \\ pusha
        \\ mov 32(%%esp), %%eax
        \\ push %%eax
        \\ call irqHandler
        \\ add $4, %%esp
        \\ popa
        \\ add $8, %%esp
        \\ iret
    );
}
