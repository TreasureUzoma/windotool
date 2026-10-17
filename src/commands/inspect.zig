const std = @import("std");
const win = @import("../utils/windows.zig");

/// Structured window information for observability
pub const WindowState = struct {
    hwnd: usize,
    title: []const u8,
    class_name: []const u8,
    process_id: u32,
    thread_id: u32,
    rect: Rect,
    is_visible: bool,
    is_enabled: bool,
    is_minimized: bool,
    is_maximized: bool,
    has_focus: bool,
    z_order: i32,
    
    pub const Rect = struct {
        x: i32,
        y: i32,
        width: i32,
        height: i32,
    };
};

/// Structured process information
pub const ProcessState = struct {
    pid: u32,
    name: []const u8,
    exe_path: ?[]const u8,
    window_count: u32,
    memory_usage: u64,
    cpu_time: u64,
};

/// Screen region for inspection
pub const ScreenRegion = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    
    pub fn contains(self: ScreenRegion, x: i32, y: i32) bool {
        return x >= self.x and x < self.x + self.width and
               y >= self.y and y < self.y + self.height;
    }
};

/// Get detailed window state by handle
pub fn getWindowState(allocator: std.mem.Allocator, hwnd: win.HWND) !WindowState {
    // Get window title
    var title_buf: [256]u8 = undefined;
    const title_len = win.GetWindowTextA(hwnd, &title_buf, title_buf.len);
    const title = try allocator.dupe(u8, title_buf[0..@intCast(title_len)]);
    
    // Get class name
    var class_buf: [256]u8 = undefined;
    const class_len = win.GetClassNameA(hwnd, &class_buf, class_buf.len);
    const class_name = try allocator.dupe(u8, class_buf[0..@intCast(class_len)]);
    
    // Get process and thread IDs
    var process_id: u32 = 0;
    const thread_id = win.GetWindowThreadProcessId(hwnd, &process_id);
    
    // Get window rectangle
    var rect: win.RECT = undefined;
    _ = win.GetWindowRect(hwnd, &rect);
    
    // Get window state flags
    const is_visible = win.IsWindowVisible(hwnd) != 0;
    const is_enabled = win.IsWindowEnabled(hwnd) != 0;
    
    // Check if minimized or maximized
    var placement: win.WINDOWPLACEMENT = .{
        .length = @sizeOf(win.WINDOWPLACEMENT),
        .flags = 0,
        .showCmd = 0,
        .ptMinPosition = .{ .x = 0, .y = 0 },
        .ptMaxPosition = .{ .x = 0, .y = 0 },
        .rcNormalPosition = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    };
    _ = win.GetWindowPlacement(hwnd, &placement);
    
    const is_minimized = placement.showCmd == win.SW_SHOWMINIMIZED;
    const is_maximized = placement.showCmd == win.SW_SHOWMAXIMIZED;
    
    // Check if focused
    const foreground = win.GetForegroundWindow();
    const has_focus = (hwnd == foreground);
    
    return WindowState{
        .hwnd = @intFromPtr(hwnd),
        .title = title,
        .class_name = class_name,
        .process_id = process_id,
        .thread_id = thread_id,
        .rect = .{
            .x = rect.left,
            .y = rect.top,
            .width = rect.right - rect.left,
            .height = rect.bottom - rect.top,
        },
        .is_visible = is_visible,
        .is_enabled = is_enabled,
        .is_minimized = is_minimized,
        .is_maximized = is_maximized,
        .has_focus = has_focus,
        .z_order = 0, // TODO: Calculate actual z-order
    };
}

/// Get all visible windows with their states
pub fn getAllWindowStates(allocator: std.mem.Allocator) ![]WindowState {
    var states = std.ArrayList(WindowState).init(allocator);
    errdefer states.deinit();
    
    const Context = struct {
        allocator: std.mem.Allocator,
        states: *std.ArrayList(WindowState),
    };
    
    var context = Context{
        .allocator = allocator,
        .states = &states,
    };
    
    const callback = struct {
        fn enumCallback(hwnd: win.HWND, lParam: win.LPARAM) callconv(.C) win.BOOL {
            const ctx = @as(*Context, @ptrFromInt(@as(usize, @intCast(lParam))));
            
            // Only include visible windows with titles
            if (win.IsWindowVisible(hwnd) == 0) return 1;
            
            var title_buf: [256]u8 = undefined;
            const title_len = win.GetWindowTextA(hwnd, &title_buf, title_buf.len);
            if (title_len == 0) return 1;
            
            const state = getWindowState(ctx.allocator, hwnd) catch return 1;
            ctx.states.append(state) catch return 1;
            
            return 1; // Continue enumeration
        }
    }.enumCallback;
    
    _ = win.EnumWindows(callback, @intCast(@intFromPtr(&context)));
    
    return states.toOwnedSlice();
}

/// Find window by title substring (case-insensitive)
pub fn findWindowByTitle(allocator: std.mem.Allocator, title_query: []const u8) !?WindowState {
    const states = try getAllWindowStates(allocator);
    defer {
        for (states) |state| {
            allocator.free(state.title);
            allocator.free(state.class_name);
        }
        allocator.free(states);
    }
    
    for (states) |state| {
        // Case-insensitive substring match
        var i: usize = 0;
        while (i + title_query.len <= state.title.len) : (i += 1) {
            const slice = state.title[i..i + title_query.len];
            if (std.ascii.eqlIgnoreCase(slice, title_query)) {
                return WindowState{
                    .hwnd = state.hwnd,
                    .title = try allocator.dupe(u8, state.title),
                    .class_name = try allocator.dupe(u8, state.class_name),
                    .process_id = state.process_id,
                    .thread_id = state.thread_id,
                    .rect = state.rect,
                    .is_visible = state.is_visible,
                    .is_enabled = state.is_enabled,
                    .is_minimized = state.is_minimized,
                    .is_maximized = state.is_maximized,
                    .has_focus = state.has_focus,
                    .z_order = state.z_order,
                };
            }
        }
    }
    
    return null;
}

/// Get process information by PID
pub fn getProcessState(allocator: std.mem.Allocator, pid: u32) !?ProcessState {
    const handle = win.OpenProcess(win.PROCESS_QUERY_INFORMATION | win.PROCESS_VM_READ, 0, pid);
    if (handle == null) return null;
    defer _ = win.CloseHandle(handle);
    
    // Get process name
    var name_buf: [win.MAX_PATH]u8 = undefined;
    var name_len: u32 = win.MAX_PATH;
    _ = win.QueryFullProcessImageNameA(handle, 0, &name_buf, &name_len);
    
    const full_path = try allocator.dupe(u8, name_buf[0..name_len]);
    
    // Extract just the filename
    var name_start: usize = 0;
    for (full_path, 0..) |c, i| {
        if (c == '\\' or c == '/') name_start = i + 1;
    }
    const name = try allocator.dupe(u8, full_path[name_start..]);
    
    // Get memory usage
    var mem_counters: win.PROCESS_MEMORY_COUNTERS = undefined;
    mem_counters.cb = @sizeOf(win.PROCESS_MEMORY_COUNTERS);
    _ = win.GetProcessMemoryInfo(handle, &mem_counters, @sizeOf(win.PROCESS_MEMORY_COUNTERS));
    
    // Count windows for this process
    var window_count: u32 = 0;
    const states = try getAllWindowStates(allocator);
    defer {
        for (states) |state| {
            allocator.free(state.title);
            allocator.free(state.class_name);
        }
        allocator.free(states);
    }
    
    for (states) |state| {
        if (state.process_id == pid) window_count += 1;
    }
    
    return ProcessState{
        .pid = pid,
        .name = name,
        .exe_path = full_path,
        .window_count = window_count,
        .memory_usage = mem_counters.WorkingSetSize,
        .cpu_time = 0, // TODO: Get CPU time
    };
}

/// Get pixel color at coordinates (for visual verification)
pub fn getPixelColor(x: i32, y: i32) !u32 {
    const hdc = win.GetDC(null);
    defer _ = win.ReleaseDC(null, hdc);
    
    const color = win.GetPixel(hdc, x, y);
    if (color == 0xFFFFFFFF) return error.InvalidCoordinate;
    
    return color;
}

/// Capture screen region as bitmap data
pub fn captureScreenRegion(allocator: std.mem.Allocator, region: ScreenRegion) ![]u8 {
    const hdc_screen = win.GetDC(null);
    defer _ = win.ReleaseDC(null, hdc_screen);
    
    const hdc_mem = win.CreateCompatibleDC(hdc_screen);
    defer _ = win.DeleteDC(hdc_mem);
    
    const hbm = win.CreateCompatibleBitmap(hdc_screen, region.width, region.height);
    defer _ = win.DeleteObject(hbm);
    
    const old_bm = win.SelectObject(hdc_mem, hbm);
    defer _ = win.SelectObject(hdc_mem, old_bm);
    
    _ = win.BitBlt(hdc_mem, 0, 0, region.width, region.height, hdc_screen, region.x, region.y, win.SRCCOPY);
    
    // Get bitmap data
    var bmi: win.BITMAPINFO = undefined;
    bmi.bmiHeader.biSize = @sizeOf(win.BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = region.width;
    bmi.bmiHeader.biHeight = -region.height; // Top-down DIB
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = win.BI_RGB;
    
    const data_size = @as(usize, @intCast(region.width * region.height * 4));
    const data = try allocator.alloc(u8, data_size);
    
    _ = win.GetDIBits(hdc_mem, hbm, 0, @intCast(region.height), data.ptr, &bmi, win.DIB_RGB_COLORS);
    
    return data;
}

/// Get desktop snapshot - all observable state
pub fn getDesktopSnapshot(allocator: std.mem.Allocator) !DesktopSnapshot {
    const windows = try getAllWindowStates(allocator);
    
    // Get screen dimensions
    const screen_width = win.GetSystemMetrics(win.SM_CXSCREEN);
    const screen_height = win.GetSystemMetrics(win.SM_CYSCREEN);
    
    // Get foreground window
    const fg_hwnd = win.GetForegroundWindow();
    var focused_window: ?usize = null;
    if (fg_hwnd != null) {
        focused_window = @intFromPtr(fg_hwnd);
    }
    
    // Get cursor position
    var cursor_pos: win.POINT = undefined;
    _ = win.GetCursorPos(&cursor_pos);
    
    return DesktopSnapshot{
        .timestamp = std.time.milliTimestamp(),
        .screen_width = screen_width,
        .screen_height = screen_height,
        .cursor_x = cursor_pos.x,
        .cursor_y = cursor_pos.y,
        .focused_window_hwnd = focused_window,
        .windows = windows,
        .window_count = @intCast(windows.len),
    };
}

pub const DesktopSnapshot = struct {
    timestamp: i64,
    screen_width: i32,
    screen_height: i32,
    cursor_x: i32,
    cursor_y: i32,
    focused_window_hwnd: ?usize,
    windows: []WindowState,
    window_count: usize,
    
    pub fn deinit(self: *DesktopSnapshot, allocator: std.mem.Allocator) void {
        for (self.windows) |window| {
            allocator.free(window.title);
            allocator.free(window.class_name);
        }
        allocator.free(self.windows);
    }
};
