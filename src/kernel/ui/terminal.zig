// Terminal Screen (F2)
// Interactive shell interface

const console = @import("../io/console.zig");
const buffer = @import("../io/buffer.zig");

// Track prompt position to prevent backspace from deleting it
var prompt_column: usize = 0;
var prompt_row: usize = 0;

pub fn draw() void {
    console.clear();
    console.printColored("  Terminal\n", .{}, .cyan, .black);
    console.printColored("  --------\n\n", .{}, .cyan, .black);
    printPrompt();
}

pub fn printPrompt() void {
    console.printColored("  > ", .{}, .light_green, .black);
    // Remember cursor position after prompt
    prompt_column = buffer.getColumn();
    prompt_row = buffer.getRow();
}

/// Check if backspace is allowed (not at prompt position)
pub fn canBackspace() bool {
    const col = buffer.getColumn();
    const row = buffer.getRow();
    // Allow backspace only if we're past the prompt on the same line
    // or on a different line (though terminal doesn't allow multiline input)
    return row != prompt_row or col > prompt_column;
}
