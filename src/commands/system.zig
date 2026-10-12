const std = @import("std");
const win = @import("../utils/windows.zig");

/// Get screen resolution
pub fn getScreenSize() !struct { width: i32, height: i32 } {
    const width = win.GetSystemMetrics(win.SM_CXSCREEN);
    const height = win.GetSystemMetrics(win.SM_CYSCREEN);

    if (width <= 0 or height <= 0) {
        return error.GetScreenSizeFailed;
    }

    return .{ .width = width, .height = height };
}

/// Get active window title
pub fn getActiveWindowTitle(allocator: std.mem.Allocator) ![]u8 {
    const hwnd = win.GetForegroundWindow() orelse return error.NoActiveWindow;

    var buffer: [512]u16 = undefined;
    const length = win.GetWindowTextW(hwnd, &buffer, buffer.len);

    if (length <= 0) {
        return allocator.dupe(u8, "(no title)");
    }

    return std.unicode.utf16LeToUtf8Alloc(allocator, buffer[0..@intCast(length)]);
}

/// Get active window handle
pub fn getActiveWindowHandle() !usize {
    const hwnd = win.GetForegroundWindow() orelse return error.NoActiveWindow;
    return @intFromPtr(hwnd);
}

/// Get pixel color at coordinates
pub fn getPixelColor(x: i32, y: i32) !u32 {
    const hdc = win.GetDC(null) orelse return error.GetDCFailed;
    defer _ = win.ReleaseDC(null, hdc);

    const color = win.GetPixel(hdc, x, y);
    if (color == 0xFFFFFFFF) { // CLR_INVALID
        return error.GetPixelFailed;
    }

    return color;
}

/// Wait for specified milliseconds
pub fn wait(ms: u32) void {
    win.Sleep(ms);
}

/// Get current system time
pub fn getSystemTime() !struct { year: u16, month: u16, day: u16, hour: u16, minute: u16, second: u16 } {
    var st: win.SYSTEMTIME = undefined;
    win.GetLocalTime(&st);

    return .{
        .year = st.wYear,
        .month = st.wMonth,
        .day = st.wDay,
        .hour = st.wHour,
        .minute = st.wMinute,
        .second = st.wSecond,
    };
}

/// Check if process is running
pub fn isProcessRunning(allocator: std.mem.Allocator, process_name: []const u8) !bool {
    const exe_name = if (std.mem.endsWith(u8, process_name, ".exe"))
        process_name
    else
        try std.mem.concat(allocator, u8, &.{ process_name, ".exe" });
    defer if (!std.mem.endsWith(u8, process_name, ".exe")) allocator.free(exe_name);

    var child = std.process.Child.init(
        &.{ "tasklist.exe", "/FI", try std.fmt.allocPrint(allocator, "IMAGENAME eq {s}", .{exe_name}), "/NH" },
        allocator,
    );
    defer allocator.free(child.argv[2]);

    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Ignore;

    try child.spawn();

    const stdout = try child.stdout.?.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(stdout);

    _ = try child.wait();

    // If process is running, output will contain the exe name
    return std.mem.indexOf(u8, stdout, exe_name) != null;
}

/// Get environment variable
pub fn getEnvVar(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    return std.process.getEnvVarOwned(allocator, name);
}
