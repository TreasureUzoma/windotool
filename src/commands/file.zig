const std = @import("std");

/// Read entire file content
pub fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const max_size = 100 * 1024 * 1024; // 100 MB limit
    return try file.readToEndAlloc(allocator, max_size);
}

/// Write content to file
pub fn writeFile(path: []const u8, content: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    try file.writeAll(content);
}

/// Append content to file
pub fn appendFile(path: []const u8, content: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
    defer file.close();

    try file.seekFromEnd(0);
    try file.writeAll(content);
}

/// Check if file exists
pub fn exists(path: []const u8) bool {
    std.fs.cwd().access(path, .{}) catch return false;
    return true;
}

/// Delete file
pub fn deleteFile(path: []const u8) !void {
    try std.fs.cwd().deleteFile(path);
}

/// Get file size
pub fn getSize(path: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const stat = try file.stat();
    return stat.size;
}

/// List files in directory
pub fn listDir(_: std.mem.Allocator, path: []const u8) !void {
    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();
    var count: usize = 0;

    while (try iter.next()) |entry| {
        const type_str = switch (entry.kind) {
            .file => "[FILE]",
            .directory => "[DIR] ",
            .sym_link => "[LINK]",
            else => "[?]   ",
        };

        std.debug.print("{s} {s}\n", .{ type_str, entry.name });
        count += 1;
    }

    if (count == 0) {
        std.debug.print("(empty directory)\n", .{});
    }
}

/// Create directory
pub fn makeDir(path: []const u8) !void {
    try std.fs.cwd().makePath(path);
}

/// Copy file
pub fn copyFile(source: []const u8, dest: []const u8) !void {
    try std.fs.cwd().copyFile(source, std.fs.cwd(), dest, .{});
}

/// Move/rename file
pub fn moveFile(source: []const u8, dest: []const u8) !void {
    try std.fs.cwd().rename(source, dest);
}
