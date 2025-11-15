const std = @import("std");

pub fn main() !void {
    const tmp: u32 = undefined;
    const t2 = @TypeOf(tmp);
    std.debug.print("Hello, {any}!\n", .{t2});
}
