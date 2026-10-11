// This is the root module file for windotool
// It re-exports the public API for use as a library

const std = @import("std");

// Export command modules
pub const app = @import("commands/app.zig");
pub const window = @import("commands/window.zig");
pub const mouse = @import("commands/mouse.zig");
pub const keyboard = @import("commands/keyboard.zig");
pub const screenshot = @import("commands/screenshot.zig");

// Export utilities
pub const windows = @import("utils/windows.zig");
pub const errors = @import("utils/errors.zig");

// Export main command dispatcher
pub const executeCommand = @import("utils.zig").executeCommand;
pub const executeBatch = @import("utils.zig").executeBatch;
pub const tokenizeLine = @import("utils.zig").tokenizeLine;

test "windotool module" {
    @import("std").testing.refAllDecls(@This());
}
