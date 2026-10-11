const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); // skip program name

    var args_list: std.ArrayList([]const u8) = .empty;
    defer args_list.deinit(allocator);

    while (args.next()) |arg| {
        try args_list.append(allocator, arg);
    }

    // Execute command - will print help if no args
    utils.executeCommand(allocator, args_list.items) catch |err| {
        std.debug.print("Fatal error: {any}\n", .{err});
        std.process.exit(1);
    };
}
