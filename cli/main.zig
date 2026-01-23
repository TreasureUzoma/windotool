const std = @import("std");

const MOUSEEVENTF_LEFTDOWN: u32 = 0x0002;
const MOUSEEVENTF_LEFTUP: u32 = 0x0004;
const MOUSEEVENTF_RIGHTDOWN: u32 = 0x0008;
const MOUSEEVENTF_RIGHTUP: u32 = 0x0010;

extern "user32" fn SetCursorPos(x: i32, y: i32) callconv(.winapi) bool;
extern "user32" fn mouse_event(dwFlags: u32, dx: u32, dy: u32, cButtons: u32, dwExtraInfo: usize) callconv(.winapi) void;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next();

    const helpMessage =
        \\windotool - lightweight, fast, native Windows automation CLI written in Zig
        \\usage:
        \\  mouse move <x> <y>       Move the mouse cursor to coordinates (x, y)
        \\  mouse click <button>     Click the mouse button ("left" or "right")
    ;

    const cmd = args.next() orelse {
        std.debug.print("{s}\n", .{helpMessage});
        return;
    };
    if (!std.mem.eql(u8, cmd, "mouse")) {
        std.debug.print("{s}\n", .{helpMessage});
        return;
    }

    const action = args.next() orelse return;

    if (std.mem.eql(u8, action, "move")) {
        const x_str = args.next() orelse return;
        const y_str = args.next() orelse return;

        const x = try std.fmt.parseInt(i32, x_str, 10);
        const y = try std.fmt.parseInt(i32, y_str, 10);

        _ = SetCursorPos(x, y);
    } else if (std.mem.eql(u8, action, "click")) {
        const button = args.next() orelse return;

        if (std.mem.eql(u8, button, "left")) {
            mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
            mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
        } else if (std.mem.eql(u8, button, "right")) {
            mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
            mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
        }
    }
}
