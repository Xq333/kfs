// Multiboot header constants
const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC: u32 = 0x1BADB002;
const FLAGS: u32 = ALIGN | MEMINFO;

// Multiboot header structure
const MultibootHeader = packed struct {
    magic: u32 = MAGIC,
    flags: u32 = FLAGS,
    checksum: u32 = -(MAGIC + FLAGS),
};

// Export the multiboot header in the .multiboot section
export var multiboot_header align(4) linksection(".multiboot") = MultibootHeader{};
