// Global Descriptor Table (GDT)
// Defines memory segments for protected mode

const vga = @import("../drivers/vga.zig");

// ============================================================================
// Types
// ============================================================================

const GdtEntry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_middle: u8,
    access: u8,
    granularity: u8,
    base_high: u8,
};

const GdtPtr = packed struct {
    limit: u16,
    base: u32,
};

// ============================================================================
// Constants
// ============================================================================

const GDT_SIZE = 5;

// Access byte flags
const PRESENT: u8 = 0x80;
const DPL_RING0: u8 = 0x00;
const DPL_RING3: u8 = 0x60;
const SEGMENT: u8 = 0x10;
const EXECUTABLE: u8 = 0x08;
const READ_WRITE: u8 = 0x02;

// Granularity flags
const GRANULARITY_4K: u8 = 0x80;
const SIZE_32BIT: u8 = 0x40;

// ============================================================================
// State
// ============================================================================

var gdt: [GDT_SIZE]GdtEntry = undefined;
var gdt_ptr: GdtPtr = undefined;

// ============================================================================
// Public API
// ============================================================================

pub fn init() void {
    // Null descriptor
    setEntry(0, 0, 0, 0, 0);

    // Kernel code segment: base=0, limit=4GB, executable, readable
    setEntry(1, 0, 0xFFFFFFFF, PRESENT | DPL_RING0 | SEGMENT | EXECUTABLE | READ_WRITE, GRANULARITY_4K | SIZE_32BIT);

    // Kernel data segment: base=0, limit=4GB, writable
    setEntry(2, 0, 0xFFFFFFFF, PRESENT | DPL_RING0 | SEGMENT | READ_WRITE, GRANULARITY_4K | SIZE_32BIT);

    // User code segment
    setEntry(3, 0, 0xFFFFFFFF, PRESENT | DPL_RING3 | SEGMENT | EXECUTABLE | READ_WRITE, GRANULARITY_4K | SIZE_32BIT);

    // User data segment
    setEntry(4, 0, 0xFFFFFFFF, PRESENT | DPL_RING3 | SEGMENT | READ_WRITE, GRANULARITY_4K | SIZE_32BIT);

    // Load GDT
    gdt_ptr = .{
        .limit = @sizeOf(@TypeOf(gdt)) - 1,
        .base = @intFromPtr(&gdt),
    };

    loadGdt();
}

// ============================================================================
// Internal
// ============================================================================

fn setEntry(index: usize, base: u32, limit: u32, access: u8, granularity: u8) void {
    gdt[index] = .{
        .limit_low = @truncate(limit & 0xFFFF),
        .base_low = @truncate(base & 0xFFFF),
        .base_middle = @truncate((base >> 16) & 0xFF),
        .access = access,
        .granularity = granularity | @as(u8, @truncate((limit >> 16) & 0x0F)),
        .base_high = @truncate((base >> 24) & 0xFF),
    };
}

fn loadGdt() void {
    asm volatile (
        \\ lgdt (%[gdt_ptr])
        \\ ljmp $0x08, $1f
        \\ 1:
        \\ movw $0x10, %%ax
        \\ movw %%ax, %%ds
        \\ movw %%ax, %%es
        \\ movw %%ax, %%fs
        \\ movw %%ax, %%gs
        \\ movw %%ax, %%ss
        :
        : [gdt_ptr] "r" (&gdt_ptr),
        : .{ .eax = true });
}
