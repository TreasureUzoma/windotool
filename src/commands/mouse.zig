const std = @import("std");
const win = @import("../utils/windows.zig");

pub fn mouseMove(x: i32, y: i32) !void {
    if (win.SetCursorPos(x, y) == 0) return error.SetCursorPosFailed;
}

pub fn mouseClick(button: []const u8) void {
    if (std.mem.eql(u8, button, "left")) {
        win.mouse_event(win.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
        win.mouse_event(win.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    } else if (std.mem.eql(u8, button, "right")) {
        win.mouse_event(win.MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
        win.mouse_event(win.MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
    } else if (std.mem.eql(u8, button, "middle")) {
        win.mouse_event(win.MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, 0);
        win.mouse_event(win.MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0);
    } else if (std.mem.eql(u8, button, "double")) {
        win.mouse_event(win.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
        win.mouse_event(win.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
        win.Sleep(50);
        win.mouse_event(win.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
        win.mouse_event(win.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    } else {
        std.debug.print("Unknown mouse button: {s}\n", .{button});
    }
}

pub fn mouseScroll(delta: i32) void {
    win.mouse_event(win.MOUSEEVENTF_WHEEL, 0, 0, @bitCast(delta), 0);
}

pub fn mouseGetPos() !win.POINT {
    var pt: win.POINT = undefined;
    if (win.GetCursorPos(&pt) == 0) return error.GetCursorPosFailed;
    return pt;
}
