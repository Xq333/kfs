// Color definitions usable throughout the kernel.
pub const Color = enum(u8) {
    black = 0x0,
    blue = 0x1,
    green = 0x2,
    cyan = 0x3,
    red = 0x4,
    magenta = 0x5,
    brown = 0x6,
    light_grey = 0x7,
    dark_grey = 0x8,
    light_blue = 0x9,
    light_green = 0xA,
    light_cyan = 0xB,
    light_red = 0xC,
    light_magenta = 0xD,
    yellow = 0xE,
    white = 0xF,
};

/// Compose the attribute byte used by VGA text mode from foreground and background colors.
pub inline fn vgaEntryColor(fg: Color, bg: Color) u8 {
    return (@intFromEnum(bg) << 4) | (@intFromEnum(fg) & 0x0F);
}
