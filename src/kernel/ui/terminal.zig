// Terminal Screen (F2)
// Interactive shell interface

const console = @import("../io/console.zig");
const buffer = @import("../io/buffer.zig");
const shell = @import("../shell/shell.zig");

// Track prompt position to prevent backspace from deleting it
var prompt_column: usize = 0;
var prompt_row: usize = 0;

pub fn draw() void {
    console.clear();
    console.printColored("  Terminal\n", .{}, .cyan, .black);
    console.printColored("  --------\n\n", .{}, .cyan, .black);
    console.printColored("  Type 'help' for available commands.\n\n", .{}, .dark_gray, .black);
    shell.init();
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
    return row == prompt_row and col > prompt_column;
}

/// Handle character input from keyboard
pub fn handleChar(char: u8) void {
    if (char == '\n') {
        console.printChar('\n');
        shell.execute();
        printPrompt();
    } else if (char == '\x08') {
        // Backspace
        if (canBackspace()) {
            shell.removeChar();
            console.printChar(char);
        }
    } else {
        // Regular character
        shell.addChar(char);
        console.printChar(char);
    }
}
