const std = @import("std");
const win = @import("../utils/windows.zig");

pub fn listWindows(allocator: std.mem.Allocator) void {
    var context = WindowListContext{ .allocator = allocator };
    _ = win.EnumWindows(listWindowsCallback, @bitCast(@intFromPtr(&context)));
    if (context.count == 0) {
        std.debug.print("No visible windows found.\n", .{});
    }
}

pub fn focusWindow(allocator: std.mem.Allocator, title_query: []const u8) !void {
    var context = FindWindowContext{
        .allocator = allocator,
        .query = title_query,
    };
    _ = win.EnumWindows(findWindowCallback, @bitCast(@intFromPtr(&context)));
    defer if (context.found_title) |t| allocator.free(t);

    const hwnd = context.found_hwnd orelse {
        std.debug.print("No window found matching title: \"{s}\"\n", .{title_query});
        return error.WindowNotFound;
    };

    if (win.IsIconic(hwnd) != 0) {
        _ = win.ShowWindow(hwnd, win.SW_RESTORE);
    } else {
        _ = win.ShowWindow(hwnd, win.SW_SHOW);
    }
    _ = win.BringWindowToTop(hwnd);
    _ = win.SetForegroundWindow(hwnd);

    if (context.found_title) |t| {
        std.debug.print("Focused window: \"{s}\"\n", .{t});
    } else {
        std.debug.print("Focused window matching: \"{s}\"\n", .{title_query});
    }
}

pub fn moveWindow(
    allocator: std.mem.Allocator,
    title_query: []const u8,
    new_x: ?i32,
    new_y: ?i32,
    new_w: ?i32,
    new_h: ?i32,
) !void {
    var context = FindWindowContext{
        .allocator = allocator,
        .query = title_query,
    };
    _ = win.EnumWindows(findWindowCallback, @bitCast(@intFromPtr(&context)));
    defer if (context.found_title) |t| allocator.free(t);

    const hwnd = context.found_hwnd orelse {
        std.debug.print("No window found matching title: \"{s}\"\n", .{title_query});
        return error.WindowNotFound;
    };

    var rect: win.RECT = undefined;
    if (win.GetWindowRect(hwnd, &rect) == 0) return error.GetWindowRectFailed;

    const cur_w = rect.right - rect.left;
    const cur_h = rect.bottom - rect.top;

    const x = new_x orelse rect.left;
    const y = new_y orelse rect.top;
    const w = new_w orelse cur_w;
    const h = new_h orelse cur_h;

    if (win.IsIconic(hwnd) != 0 or win.IsZoomed(hwnd) != 0) {
        _ = win.ShowWindow(hwnd, win.SW_RESTORE);
    }

    if (win.MoveWindow(hwnd, x, y, w, h, 1) == 0) {
        std.debug.print("Failed to move window.\n", .{});
        return error.MoveWindowFailed;
    }

    const title_name = context.found_title orelse title_query;
    std.debug.print("Moved window \"{s}\" -> x={d}, y={d}, w={d}, h={d}\n", .{
        title_name, x, y, w, h,
    });
}

pub fn getWindowInfo(allocator: std.mem.Allocator, title_query: []const u8) !void {
    var context = FindWindowContext{
        .allocator = allocator,
        .query = title_query,
    };
    _ = win.EnumWindows(findWindowCallback, @bitCast(@intFromPtr(&context)));
    defer if (context.found_title) |t| allocator.free(t);

    const hwnd = context.found_hwnd orelse {
        std.debug.print("No window found matching title: \"{s}\"\n", .{title_query});
        return error.WindowNotFound;
    };

    var rect: win.RECT = undefined;
    if (win.GetWindowRect(hwnd, &rect) == 0) return error.GetWindowRectFailed;

    const width = rect.right - rect.left;
    const height = rect.bottom - rect.top;

    const is_visible = win.IsWindowVisible(hwnd) != 0;
    const is_minimized = win.IsIconic(hwnd) != 0;
    const is_maximized = win.IsZoomed(hwnd) != 0;

    const title_name = context.found_title orelse title_query;

    std.debug.print("Window Information:\n", .{});
    std.debug.print("─────────────────────────────────────────\n", .{});
    std.debug.print("Title:      {s}\n", .{title_name});
    std.debug.print("Handle:     0x{X:0>8}\n", .{@intFromPtr(hwnd)});
    std.debug.print("Position:   x={d}, y={d}\n", .{ rect.left, rect.top });
    std.debug.print("Size:       w={d}, h={d}\n", .{ width, height });
    std.debug.print("State:      {s}{s}{s}\n", .{
        if (is_minimized) "Minimized" else if (is_maximized) "Maximized" else "Normal",
        if (!is_visible) " (Hidden)" else "",
        if (rect.left <= -32000) " (Off-screen)" else "",
    });
    std.debug.print("─────────────────────────────────────────\n", .{});
}

pub fn scrollWindow(allocator: std.mem.Allocator, title_query: []const u8, delta: i32) !void {
    var context = FindWindowContext{
        .allocator = allocator,
        .query = title_query,
    };
    _ = win.EnumWindows(findWindowCallback, @bitCast(@intFromPtr(&context)));
    defer if (context.found_title) |t| allocator.free(t);

    const hwnd = context.found_hwnd orelse {
        std.debug.print("No window found matching title: \"{s}\"\n", .{title_query});
        return error.WindowNotFound;
    };

    // Get window rect to calculate center position for scroll
    var rect: win.RECT = undefined;
    if (win.GetWindowRect(hwnd, &rect) == 0) return error.GetWindowRectFailed;

    // Focus the window first
    if (win.IsIconic(hwnd) != 0) {
        _ = win.ShowWindow(hwnd, win.SW_RESTORE);
    }
    _ = win.SetForegroundWindow(hwnd);
    win.Sleep(100); // Small delay to ensure window gets focus

    // Calculate center of window
    const center_x = rect.left + @divTrunc(rect.right - rect.left, 2);
    const center_y = rect.top + @divTrunc(rect.bottom - rect.top, 2);

    // Save current cursor position
    var old_pos: win.POINT = undefined;
    if (win.GetCursorPos(&old_pos) == 0) return error.GetCursorPosFailed;

    // Move cursor to window center
    if (win.SetCursorPos(center_x, center_y) == 0) return error.SetCursorPosFailed;

    // Send scroll event
    win.mouse_event(win.MOUSEEVENTF_WHEEL, 0, 0, @bitCast(delta), 0);

    // Restore cursor position
    _ = win.SetCursorPos(old_pos.x, old_pos.y);

    const title_name = context.found_title orelse title_query;
    std.debug.print("Scrolled window \"{s}\" by {d}\n", .{ title_name, delta });
}

pub fn minimizeWindow(allocator: std.mem.Allocator, title_query: []const u8) !void {
    var context = FindWindowContext{
        .allocator = allocator,
        .query = title_query,
    };
    _ = win.EnumWindows(findWindowCallback, @bitCast(@intFromPtr(&context)));
    defer if (context.found_title) |t| allocator.free(t);

    const hwnd = context.found_hwnd orelse {
        std.debug.print("No window found matching title: \"{s}\"\n", .{title_query});
        return error.WindowNotFound;
    };

    _ = win.ShowWindow(hwnd, win.SW_MINIMIZE);
    const title_name = context.found_title orelse title_query;
    std.debug.print("Minimized window \"{s}\"\n", .{title_name});
}

pub fn maximizeWindow(allocator: std.mem.Allocator, title_query: []const u8) !void {
    var context = FindWindowContext{
        .allocator = allocator,
        .query = title_query,
    };
    _ = win.EnumWindows(findWindowCallback, @bitCast(@intFromPtr(&context)));
    defer if (context.found_title) |t| allocator.free(t);

    const hwnd = context.found_hwnd orelse {
        std.debug.print("No window found matching title: \"{s}\"\n", .{title_query});
        return error.WindowNotFound;
    };

    _ = win.ShowWindow(hwnd, win.SW_MAXIMIZE);
    const title_name = context.found_title orelse title_query;
    std.debug.print("Maximized window \"{s}\"\n", .{title_name});
}

pub fn restoreWindow(allocator: std.mem.Allocator, title_query: []const u8) !void {
    var context = FindWindowContext{
        .allocator = allocator,
        .query = title_query,
    };
    _ = win.EnumWindows(findWindowCallback, @bitCast(@intFromPtr(&context)));
    defer if (context.found_title) |t| allocator.free(t);

    const hwnd = context.found_hwnd orelse {
        std.debug.print("No window found matching title: \"{s}\"\n", .{title_query});
        return error.WindowNotFound;
    };

    _ = win.ShowWindow(hwnd, win.SW_RESTORE);
    const title_name = context.found_title orelse title_query;
    std.debug.print("Restored window \"{s}\"\n", .{title_name});
}

pub fn getActiveWindow(allocator: std.mem.Allocator) !void {
    const hwnd = win.GetForegroundWindow() orelse {
        std.debug.print("No active window found\n", .{});
        return error.NoActiveWindow;
    };

    var buffer: [512]u16 = undefined;
    const length = win.GetWindowTextW(hwnd, &buffer, buffer.len);

    const title = if (length > 0)
        try std.unicode.utf16LeToUtf8Alloc(allocator, buffer[0..@intCast(length)])
    else
        try allocator.dupe(u8, "(no title)");
    defer allocator.free(title);

    var rect: win.RECT = undefined;
    if (win.GetWindowRect(hwnd, &rect) == 0) return error.GetWindowRectFailed;

    const width = rect.right - rect.left;
    const height = rect.bottom - rect.top;

    std.debug.print("Active Window:\n", .{});
    std.debug.print("  Title:    {s}\n", .{title});
    std.debug.print("  Handle:   0x{X:0>8}\n", .{@intFromPtr(hwnd)});
    std.debug.print("  Position: x={d}, y={d}\n", .{ rect.left, rect.top });
    std.debug.print("  Size:     w={d}, h={d}\n", .{ width, height });
}

// ─── Helper Contexts and Callbacks

const WindowListContext = struct {
    allocator: std.mem.Allocator,
    count: usize = 0,
};

fn listWindowsCallback(hwnd: ?*anyopaque, param: isize) callconv(.winapi) i32 {
    const context: *WindowListContext = @ptrFromInt(@as(usize, @bitCast(param)));

    if (win.IsWindowVisible(hwnd) == 0) return 1;

    var buffer: [512]u16 = undefined;
    const length = win.GetWindowTextW(hwnd, &buffer, buffer.len);
    if (length <= 0) return 1;

    var rect: win.RECT = undefined;
    if (win.GetWindowRect(hwnd, &rect) == 0) return 1;

    const width = rect.right - rect.left;
    const height = rect.bottom - rect.top;
    if (width <= 0 or height <= 0) return 1;

    const title = std.unicode.utf16LeToUtf8Alloc(
        context.allocator,
        buffer[0..@intCast(length)],
    ) catch return 1;
    defer context.allocator.free(title);

    const trimmed = std.mem.trim(u8, title, " \t\r\n");
    if (trimmed.len == 0) return 1;

    if (win.IsIconic(hwnd) != 0 or rect.left <= -32000) {
        std.debug.print("[0x{X:0>8}] \"{s}\" (minimized)\n", .{ @intFromPtr(hwnd), trimmed });
    } else {
        std.debug.print("[0x{X:0>8}] \"{s}\" (x: {d}, y: {d}, w: {d}, h: {d})\n", .{
            @intFromPtr(hwnd),
            trimmed,
            rect.left,
            rect.top,
            width,
            height,
        });
    }
    context.count += 1;

    return 1;
}

const FindWindowContext = struct {
    allocator: std.mem.Allocator,
    query: []const u8,
    found_hwnd: ?*anyopaque = null,
    found_title: ?[]u8 = null,
};

fn findWindowCallback(hwnd: ?*anyopaque, param: isize) callconv(.winapi) i32 {
    const context: *FindWindowContext = @ptrFromInt(@as(usize, @bitCast(param)));

    if (win.IsWindowVisible(hwnd) == 0) return 1;

    var buffer: [512]u16 = undefined;
    const length = win.GetWindowTextW(hwnd, &buffer, buffer.len);
    if (length <= 0) return 1;

    const title = std.unicode.utf16LeToUtf8Alloc(
        context.allocator,
        buffer[0..@intCast(length)],
    ) catch return 1;
    defer context.allocator.free(title);

    if (std.ascii.indexOfIgnoreCase(title, context.query) != null) {
        context.found_hwnd = hwnd;
        context.found_title = context.allocator.dupe(u8, title) catch null;
        return 0; // stop enumeration
    }

    return 1;
}
