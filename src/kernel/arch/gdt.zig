// Global Descriptor Table (GDT)
// Defines memory segments for protected mode
// GDT is placed at fixed address 0x00000800 as required by specification

const syslog = @import("../ui/syslog.zig");
const console = @import("../io/console.zig");

// ============================================================================
// Types
// ============================================================================

pub const GdtEntry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_middle: u8,
    access: u8,
    granularity: u8,
    base_high: u8,
};

pub const GdtPtr = packed struct {
    limit: u16,
    base: u32,
};

// ============================================================================
// Constants
// ============================================================================

/// GDT is placed at this fixed memory address
pub const GDT_BASE_ADDR: u32 = 0x00000800;

/// Number of GDT entries:
/// 0: Null descriptor
/// 1: Kernel Code
/// 2: Kernel Data
/// 3: Kernel Stack
/// 4: User Code
/// 5: User Data
/// 6: User Stack
pub const GDT_SIZE: usize = 7;

// Access byte flags
pub const PRESENT: u8 = 0x80; // Segment is present in memory
pub const DPL_RING0: u8 = 0x00; // Descriptor Privilege Level 0 (kernel)
pub const DPL_RING3: u8 = 0x60; // Descriptor Privilege Level 3 (user)
pub const SEGMENT: u8 = 0x10; // Code/Data segment (not system)
pub const EXECUTABLE: u8 = 0x08; // Code segment (executable)
pub const READ_WRITE: u8 = 0x02; // Readable (code) / Writable (data)
pub const DIRECTION: u8 = 0x04; // Direction bit (for stack: grows down)

// Granularity flags
pub const GRANULARITY_4K: u8 = 0x80; // Limit is in 4KB blocks
pub const SIZE_32BIT: u8 = 0x40; // 32-bit protected mode

// Segment selectors (index * 8 for GDT entry offset)
pub const KERNEL_CODE_SEL: u16 = 0x08; // Entry 1
pub const KERNEL_DATA_SEL: u16 = 0x10; // Entry 2
pub const KERNEL_STACK_SEL: u16 = 0x18; // Entry 3
pub const USER_CODE_SEL: u16 = 0x23; // Entry 4 | RPL 3
pub const USER_DATA_SEL: u16 = 0x2B; // Entry 5 | RPL 3
pub const USER_STACK_SEL: u16 = 0x33; // Entry 6 | RPL 3

// ============================================================================
// State (GDT placed at fixed address 0x00000800)
// ============================================================================

/// Pointer to GDT at fixed address 0x00000800
const gdt: *[GDT_SIZE]GdtEntry = @ptrFromInt(GDT_BASE_ADDR);

/// GDT pointer structure (placed right after GDT entries)
const gdt_ptr: *GdtPtr = @ptrFromInt(GDT_BASE_ADDR + @sizeOf([GDT_SIZE]GdtEntry));

// ============================================================================
// Public API
// ============================================================================

pub fn init() void {
    // Entry 0: Null descriptor (required by x86)
    setEntry(0, 0, 0, 0, 0);

    // Entry 1: Kernel Code segment
    // base=0, limit=4GB, executable, readable, ring 0
    setEntry(1, 0, 0xFFFFFFFF, PRESENT | DPL_RING0 | SEGMENT | EXECUTABLE | READ_WRITE, GRANULARITY_4K | SIZE_32BIT);

    // Entry 2: Kernel Data segment
    // base=0, limit=4GB, writable, ring 0
    setEntry(2, 0, 0xFFFFFFFF, PRESENT | DPL_RING0 | SEGMENT | READ_WRITE, GRANULARITY_4K | SIZE_32BIT);

    // Entry 3: Kernel Stack segment
    // base=0, limit=4GB, writable, ring 0, grows down
    setEntry(3, 0, 0xFFFFFFFF, PRESENT | DPL_RING0 | SEGMENT | READ_WRITE | DIRECTION, GRANULARITY_4K | SIZE_32BIT);

    // Entry 4: User Code segment
    // base=0, limit=4GB, executable, readable, ring 3
    setEntry(4, 0, 0xFFFFFFFF, PRESENT | DPL_RING3 | SEGMENT | EXECUTABLE | READ_WRITE, GRANULARITY_4K | SIZE_32BIT);

    // Entry 5: User Data segment
    // base=0, limit=4GB, writable, ring 3
    setEntry(5, 0, 0xFFFFFFFF, PRESENT | DPL_RING3 | SEGMENT | READ_WRITE, GRANULARITY_4K | SIZE_32BIT);

    // Entry 6: User Stack segment
    // base=0, limit=4GB, writable, ring 3, grows down
    setEntry(6, 0, 0xFFFFFFFF, PRESENT | DPL_RING3 | SEGMENT | READ_WRITE | DIRECTION, GRANULARITY_4K | SIZE_32BIT);

    // Set up GDT pointer
    gdt_ptr.* = .{
        .limit = @sizeOf([GDT_SIZE]GdtEntry) - 1,
        .base = GDT_BASE_ADDR,
    };

    // Load GDT into CPU
    loadGdt();

    syslog.ok("GDT loaded at 0x00000800 (7 entries)");
}

/// Returns the GDT pointer structure for debugging
pub fn getGdtPtr() GdtPtr {
    return gdt_ptr.*;
}

/// Returns a GDT entry by index for debugging
pub fn getEntry(index: usize) ?GdtEntry {
    if (index >= GDT_SIZE) return null;
    return gdt[index];
}

/// Print the current kernel stack in a human-friendly way
pub fn printStack() void {
    var ebp: u32 = undefined;
    var esp: u32 = undefined;

    // Get current stack pointers
    asm volatile (
        \\ movl %%ebp, %[ebp]
        \\ movl %%esp, %[esp]
        : [ebp] "=r" (ebp),
          [esp] "=r" (esp),
    );

    console.print("\n", .{});
    console.printColored("=== Kernel Stack Dump ===\n", .{}, .cyan, .black);
    console.print("ESP (Stack Pointer):  0x{X:0>8}\n", .{esp});
    console.print("EBP (Base Pointer):   0x{X:0>8}\n", .{ebp});
    console.print("\n", .{});

    // Print stack frames (walk the stack)
    console.printColored("Stack Frames (EBP chain):\n", .{}, .yellow, .black);
    console.print("--------------------------\n", .{});

    var frame_num: u32 = 0;
    var current_ebp = ebp;
    const max_frames: u32 = 20; // Limit to prevent infinite loops

    while (current_ebp != 0 and frame_num < max_frames) {
        // EBP points to saved EBP, EBP+4 is return address
        const saved_ebp: *const u32 = @ptrFromInt(current_ebp);
        const ret_addr: *const u32 = @ptrFromInt(current_ebp + 4);

        console.print("Frame {d:2}: EBP=0x{X:0>8}  RET=0x{X:0>8}\n", .{ frame_num, current_ebp, ret_addr.* });

        // Move to previous frame
        current_ebp = saved_ebp.*;
        frame_num += 1;
    }

    if (frame_num == 0) {
        console.print("  (no stack frames found)\n", .{});
    }

    console.print("\n", .{});

    // Print raw stack content
    console.printColored("Raw Stack Content (top 64 bytes):\n", .{}, .yellow, .black);
    console.print("----------------------------------\n", .{});

    const stack_ptr: [*]const u32 = @ptrFromInt(esp);
    var i: usize = 0;
    while (i < 16) : (i += 1) { // 16 * 4 = 64 bytes
        if (i % 4 == 0) {
            console.print("0x{X:0>8}: ", .{esp + @as(u32, @intCast(i * 4))});
        }
        console.print("{X:0>8} ", .{stack_ptr[i]});
        if (i % 4 == 3) {
            console.print("\n", .{});
        }
    }
    console.print("\n", .{});
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
        \\ movw $0x18, %%ax
        \\ movw %%ax, %%ss
        :
        : [gdt_ptr] "r" (gdt_ptr),
    );
}

// ============================================================================
// Debug: Print GDT Information
// ============================================================================

/// Print detailed GDT information for debugging
pub fn printGdtInfo() void {
    console.print("\n", .{});
    console.printColored("=== GDT Information ===\n", .{}, .cyan, .black);
    console.print("GDT Base Address: 0x{X:0>8}\n", .{GDT_BASE_ADDR});
    console.print("GDT Size:         {d} entries ({d} bytes)\n", .{ GDT_SIZE, @sizeOf([GDT_SIZE]GdtEntry) });
    console.print("\n", .{});

    const entry_names = [_][]const u8{
        "Null",
        "Kernel Code",
        "Kernel Data",
        "Kernel Stack",
        "User Code",
        "User Data",
        "User Stack",
    };

    console.printColored("Idx  Selector  Name          Base       Limit      Access Gran\n", .{}, .yellow, .black);
    console.print("---  --------  ------------  ---------- ---------- ------ ----\n", .{});

    for (0..GDT_SIZE) |i| {
        const entry = gdt[i];
        const base: u32 = @as(u32, entry.base_high) << 24 |
            @as(u32, entry.base_middle) << 16 |
            @as(u32, entry.base_low);
        const limit: u32 = @as(u32, entry.granularity & 0x0F) << 16 |
            @as(u32, entry.limit_low);

        console.print(" {d}   0x{X:0>4}    {s: <12}  0x{X:0>8} 0x{X:0>8} 0x{X:0>2}   0x{X:0>2}\n", .{
            i,
            i * 8,
            entry_names[i],
            base,
            limit,
            entry.access,
            entry.granularity,
        });
    }
    console.print("\n", .{});
}
