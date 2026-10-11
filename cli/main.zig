const std = @import("std");
const app = @import("utils.zig");

const MOUSEEVENTF_LEFTDOWN: u32 = 0x0002;
const MOUSEEVENTF_LEFTUP: u32 = 0x0004;
const MOUSEEVENTF_RIGHTDOWN: u32 = 0x0008;
const MOUSEEVENTF_RIGHTUP: u32 = 0x0010;

extern "user32" fn SetCursorPos(x: i32, y: i32) callconv(.winapi) i32;
extern "user32" fn mouse_event(dwFlags: u32, dx: u32, dy: u32, cButtons: u32, dwExtraInfo: usize) callconv(.winapi) void;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next();

    const group = args.next() orelse {
        std.debug.print(
            "windotool\nUsage:\n  mouse move <x> <y>\n  mouse click <left|right>\n  app open <path-or-exe>\n",
            .{},
        );
        return;
    };

    if (std.mem.eql(u8, group, "mouse")) {
        const action = args.next() orelse return;

        if (std.mem.eql(u8, action, "move")) {
            const x = try std.fmt.parseInt(i32, args.next() orelse return, 10);
            const y = try std.fmt.parseInt(i32, args.next() orelse return, 10);

            if (SetCursorPos(x, y) == 0) return error.SetCursorPosFailed;
        } else if (std.mem.eql(u8, action, "click")) {
            const button = args.next() orelse return;

            if (std.mem.eql(u8, button, "left")) {
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
            } else if (std.mem.eql(u8, button, "right")) {
                mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
            } else {
                std.debug.print("Unknown mouse button: {s}\n", .{button});
            }
        }
    } else if (std.mem.eql(u8, group, "app")) {
        const action = args.next() orelse return;

        if (std.mem.eql(u8, action, "open")) {
            const app_name = args.next() orelse return;
            try app.openApp(allocator, app_name);
        } else {
            std.debug.print("Unknown app action: {s}\n", .{action});
        }
    } else {
        std.debug.print("Unknown command: {s}\n", .{group});
    }
}
