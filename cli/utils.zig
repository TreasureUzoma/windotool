const std = @import("std");

extern "shell32" fn ShellExecuteW(
    hwnd: ?*anyopaque,
    lpOperation: ?[*:0]const u16,
    lpFile: [*:0]const u16,
    lpParameters: ?[*:0]const u16,
    lpDirectory: ?[*:0]const u16,
    nShowCmd: i32,
) callconv(.winapi) isize;

pub fn openApp(allocator: std.mem.Allocator, app: []const u8) !void {
    const app_wide = try std.unicode.utf8ToUtf16LeAllocZ(allocator, app);
    defer allocator.free(app_wide);

    const operation = std.unicode.utf8ToUtf16LeAllocZ(allocator, "open") catch return error.OutOfMemory;
    defer allocator.free(operation);

    const result = ShellExecuteW(
        null,
        operation,
        app_wide,
        null,
        null,
        1,
    );

    if (result <= 32) {
        std.debug.print("Failed to open: {s}\n", .{app});
        std.debug.print("Check if it exists and if the path is correct.\n", .{});
    }
}
