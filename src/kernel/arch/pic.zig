// Programmable Interrupt Controller (8259 PIC)
// Handles hardware interrupt routing

const vga = @import("../drivers/vga.zig");

// ============================================================================
// Constants
// ============================================================================

const PIC1_COMMAND: u16 = 0x20;
const PIC1_DATA: u16 = 0x21;
const PIC2_COMMAND: u16 = 0xA0;
const PIC2_DATA: u16 = 0xA1;

const ICW1_INIT: u8 = 0x10;
const ICW1_ICW4: u8 = 0x01;
const ICW4_8086: u8 = 0x01;
const PIC_EOI: u8 = 0x20;

// Remap IRQs to start at interrupt 32
pub const IRQ_OFFSET: u8 = 32;

// ============================================================================
// Public API
// ============================================================================

pub fn init() void {
    // Save masks
    const mask1 = vga.inb(PIC1_DATA);
    const mask2 = vga.inb(PIC2_DATA);

    // Start initialization (ICW1)
    vga.outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);
    ioWait();
    vga.outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
    ioWait();

    // Set vector offsets (ICW2)
    vga.outb(PIC1_DATA, IRQ_OFFSET); // IRQ 0-7 -> INT 32-39
    ioWait();
    vga.outb(PIC2_DATA, IRQ_OFFSET + 8); // IRQ 8-15 -> INT 40-47
    ioWait();

    // Configure cascading (ICW3)
    vga.outb(PIC1_DATA, 4); // Slave at IRQ2
    ioWait();
    vga.outb(PIC2_DATA, 2); // Cascade identity
    ioWait();

    // Set 8086 mode (ICW4)
    vga.outb(PIC1_DATA, ICW4_8086);
    ioWait();
    vga.outb(PIC2_DATA, ICW4_8086);
    ioWait();

    // Restore saved masks
    vga.outb(PIC1_DATA, mask1);
    vga.outb(PIC2_DATA, mask2);

    // Mask all interrupts except keyboard (IRQ1)
    vga.outb(PIC1_DATA, 0xFD); // 11111101 - only IRQ1 enabled
    vga.outb(PIC2_DATA, 0xFF); // All masked
}

/// Send End-Of-Interrupt signal
pub fn sendEOI(irq: u8) void {
    if (irq >= 8) {
        vga.outb(PIC2_COMMAND, PIC_EOI);
    }
    vga.outb(PIC1_COMMAND, PIC_EOI);
}

/// Enable (unmask) an IRQ
pub fn enableIrq(irq: u8) void {
    if (irq < 8) {
        const mask = vga.inb(PIC1_DATA) & ~(@as(u8, 1) << @intCast(irq));
        vga.outb(PIC1_DATA, mask);
    } else {
        const mask = vga.inb(PIC2_DATA) & ~(@as(u8, 1) << @intCast(irq - 8));
        vga.outb(PIC2_DATA, mask);
    }
}

/// Disable (mask) an IRQ
pub fn disableIrq(irq: u8) void {
    if (irq < 8) {
        const mask = vga.inb(PIC1_DATA) | (@as(u8, 1) << @intCast(irq));
        vga.outb(PIC1_DATA, mask);
    } else {
        const mask = vga.inb(PIC2_DATA) | (@as(u8, 1) << @intCast(irq - 8));
        vga.outb(PIC2_DATA, mask);
    }
}

// ============================================================================
// Internal
// ============================================================================

fn ioWait() void {
    vga.outb(0x80, 0);
}
