const std = @import("std");
const win = @import("../utils/windows.zig");

/// Get text from clipboard
pub fn getText(allocator: std.mem.Allocator) ![]u8 {
    if (win.OpenClipboard(null) == 0) return error.OpenClipboardFailed;
    defer _ = win.CloseClipboard();

    const handle = win.GetClipboardData(win.CF_UNICODETEXT);
    if (handle == null) return error.NoClipboardData;

    const data_ptr = win.GlobalLock(handle);
    if (data_ptr == null) return error.LockClipboardFailed;
    defer _ = win.GlobalUnlock(handle);

    const wide_str = @as([*:0]const u16, @ptrCast(@alignCast(data_ptr)));
    const len = std.mem.indexOfSentinel(u16, 0, wide_str);
    
    return std.unicode.utf16LeToUtf8Alloc(allocator, wide_str[0..len]);
}

/// Set clipboard text
pub fn setText(allocator: std.mem.Allocator, text: []const u8) !void {
    // Convert UTF-8 to UTF-16
    const wide_text = try std.unicode.utf8ToUtf16LeAllocZ(allocator, text);
    defer allocator.free(wide_text);

    const byte_size = (wide_text.len + 1) * @sizeOf(u16);

    // Allocate global memory
    const handle = win.GlobalAlloc(win.GMEM_MOVEABLE, byte_size);
    if (handle == null) return error.GlobalAllocFailed;

    const mem_ptr = win.GlobalLock(handle);
    if (mem_ptr == null) {
        _ = win.GlobalFree(handle);
        return error.GlobalLockFailed;
    }

    // Copy text to global memory
    const dest = @as([*]u16, @ptrCast(@alignCast(mem_ptr)));
    @memcpy(dest[0..wide_text.len], wide_text);
    dest[wide_text.len] = 0; // Null terminator

    _ = win.GlobalUnlock(handle);

    // Open clipboard and set data
    if (win.OpenClipboard(null) == 0) {
        _ = win.GlobalFree(handle);
        return error.OpenClipboardFailed;
    }
    defer _ = win.CloseClipboard();

    if (win.EmptyClipboard() == 0) {
        _ = win.GlobalFree(handle);
        return error.EmptyClipboardFailed;
    }

    if (win.SetClipboardData(win.CF_UNICODETEXT, handle) == null) {
        _ = win.GlobalFree(handle);
        return error.SetClipboardDataFailed;
    }

    // Note: Don't free handle - clipboard owns it now
}

/// Clear clipboard
pub fn clear() !void {
    if (win.OpenClipboard(null) == 0) return error.OpenClipboardFailed;
    defer _ = win.CloseClipboard();

    if (win.EmptyClipboard() == 0) return error.EmptyClipboardFailed;
}
