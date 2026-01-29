// Interrupt Descriptor Table (IDT)
// Sets up CPU interrupt/exception handlers for x86

const syslog = @import("../ui/syslog.zig");

// ============================================================================
// Types
// ============================================================================

const IdtEntry = packed struct {
    offset_low: u16,
    selector: u16,
    zero: u8 = 0,
    type_attr: u8,
    offset_high: u16,
};

const IdtPtr = packed struct {
    limit: u16,
    base: u32,
};

// ============================================================================
// Constants
// ============================================================================

const IDT_SIZE = 256;
const KERNEL_CS = 0x08;
const INTERRUPT_GATE: u8 = 0x8E; // Present, DPL=0, 32-bit interrupt gate

// ============================================================================
// State
// ============================================================================

var idt: [IDT_SIZE]IdtEntry = [_]IdtEntry{.{
    .offset_low = 0,
    .selector = 0,
    .type_attr = 0,
    .offset_high = 0,
}} ** IDT_SIZE;

var idt_ptr: IdtPtr = undefined;

// ISR stubs (defined in isr.zig)
const isr = @import("isr.zig");

// ============================================================================
// Public API
// ============================================================================

pub fn init() void {
    // Set up exception handlers (0-31)
    setGate(0, isr.isr0);
    setGate(1, isr.isr1);
    setGate(2, isr.isr2);
    setGate(3, isr.isr3);
    setGate(4, isr.isr4);
    setGate(5, isr.isr5);
    setGate(6, isr.isr6);
    setGate(7, isr.isr7);
    setGate(8, isr.isr8);
    setGate(9, isr.isr9);
    setGate(10, isr.isr10);
    setGate(11, isr.isr11);
    setGate(12, isr.isr12);
    setGate(13, isr.isr13);
    setGate(14, isr.isr14);
    setGate(15, isr.isr15);
    setGate(16, isr.isr16);
    setGate(17, isr.isr17);
    setGate(18, isr.isr18);
    setGate(19, isr.isr19);
    setGate(20, isr.isr20);
    setGate(21, isr.isr21);
    setGate(22, isr.isr22);
    setGate(23, isr.isr23);
    setGate(24, isr.isr24);
    setGate(25, isr.isr25);
    setGate(26, isr.isr26);
    setGate(27, isr.isr27);
    setGate(28, isr.isr28);
    setGate(29, isr.isr29);
    setGate(30, isr.isr30);
    setGate(31, isr.isr31);

    // Set up IRQ handlers (32-47)
    setGate(32, isr.irq0);
    setGate(33, isr.irq1); // Keyboard
    setGate(34, isr.irq2);
    setGate(35, isr.irq3);
    setGate(36, isr.irq4);
    setGate(37, isr.irq5);
    setGate(38, isr.irq6);
    setGate(39, isr.irq7);
    setGate(40, isr.irq8);
    setGate(41, isr.irq9);
    setGate(42, isr.irq10);
    setGate(43, isr.irq11);
    setGate(44, isr.irq12);
    setGate(45, isr.irq13);
    setGate(46, isr.irq14);
    setGate(47, isr.irq15);

    // Load IDT
    idt_ptr = .{
        .limit = @sizeOf(@TypeOf(idt)) - 1,
        .base = @intFromPtr(&idt),
    };

    asm volatile ("lidt (%[idt_ptr])"
        :
        : [idt_ptr] "r" (&idt_ptr),
    );

    syslog.ok("IDT loaded (256 interrupt gates)");
}

pub fn enableInterrupts() void {
    asm volatile ("sti");
}

pub fn disableInterrupts() void {
    asm volatile ("cli");
}

// ============================================================================
// Internal
// ============================================================================

fn setGate(n: u8, handler: *const fn () callconv(.naked) void) void {
    const addr = @intFromPtr(handler);
    idt[n] = .{
        .offset_low = @truncate(addr & 0xFFFF),
        .selector = KERNEL_CS,
        .type_attr = INTERRUPT_GATE,
        .offset_high = @truncate((addr >> 16) & 0xFFFF),
    };
}
