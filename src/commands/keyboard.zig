const std = @import("std");
const win = @import("../utils/windows.zig");

pub fn sendKeyCombo(combo: []const u8) !void {
    var keys: [8]u16 = undefined;
    var key_count: usize = 0;

    var iter = std.mem.splitScalar(u8, combo, '+');
    while (iter.next()) |part| {
        if (key_count >= keys.len) {
            std.debug.print("Too many keys in combination (max 8).\n", .{});
            return error.TooManyKeys;
        }

        const vk = keyNameToVk(part) orelse {
            std.debug.print("Unknown key: {s}\n", .{part});
            return error.UnknownKey;
        };

        keys[key_count] = vk;
        key_count += 1;
    }

    if (key_count == 0) {
        std.debug.print("No keys specified.\n", .{});
        return error.NoKeys;
    }

    const total_events = key_count * 2;
    var inputs: [16]win.INPUT = undefined;

    // Key-down events
    for (0..key_count) |i| {
        inputs[i] = win.INPUT{
            .type = win.INPUT_KEYBOARD,
            .u = .{ .ki = .{
                .wVk = keys[i],
            } },
        };
    }

    // Key-up events
    for (0..key_count) |i| {
        inputs[key_count + i] = win.INPUT{
            .type = win.INPUT_KEYBOARD,
            .u = .{ .ki = .{
                .wVk = keys[key_count - 1 - i],
                .dwFlags = win.KEYEVENTF_KEYUP,
            } },
        };
    }

    const sent = win.SendInput(
        @intCast(total_events),
        inputs[0..total_events].ptr,
        @sizeOf(win.INPUT),
    );

    if (sent != total_events) {
        std.debug.print("SendInput failed: sent {d}/{d} events.\n", .{ sent, total_events });
        return error.SendInputFailed;
    }
}

fn keyNameToVk(name: []const u8) ?u16 {
    // Modifier keys
    if (std.ascii.eqlIgnoreCase(name, "ctrl") or std.ascii.eqlIgnoreCase(name, "control")) return win.VK_CONTROL;
    if (std.ascii.eqlIgnoreCase(name, "alt")) return win.VK_MENU;
    if (std.ascii.eqlIgnoreCase(name, "shift")) return win.VK_SHIFT;
    if (std.ascii.eqlIgnoreCase(name, "win") or std.ascii.eqlIgnoreCase(name, "super") or std.ascii.eqlIgnoreCase(name, "cmd")) return win.VK_LWIN;

    // Special / Navigation keys
    if (std.ascii.eqlIgnoreCase(name, "enter") or std.ascii.eqlIgnoreCase(name, "return")) return win.VK_RETURN;
    if (std.ascii.eqlIgnoreCase(name, "tab")) return win.VK_TAB;
    if (std.ascii.eqlIgnoreCase(name, "escape") or std.ascii.eqlIgnoreCase(name, "esc")) return win.VK_ESCAPE;
    if (std.ascii.eqlIgnoreCase(name, "backspace") or std.ascii.eqlIgnoreCase(name, "bs")) return win.VK_BACK;
    if (std.ascii.eqlIgnoreCase(name, "delete") or std.ascii.eqlIgnoreCase(name, "del")) return win.VK_DELETE;
    if (std.ascii.eqlIgnoreCase(name, "space")) return win.VK_SPACE;
    if (std.ascii.eqlIgnoreCase(name, "home")) return win.VK_HOME;
    if (std.ascii.eqlIgnoreCase(name, "end")) return win.VK_END;
    if (std.ascii.eqlIgnoreCase(name, "pageup") or std.ascii.eqlIgnoreCase(name, "pgup")) return win.VK_PRIOR;
    if (std.ascii.eqlIgnoreCase(name, "pagedown") or std.ascii.eqlIgnoreCase(name, "pgdn")) return win.VK_NEXT;
    if (std.ascii.eqlIgnoreCase(name, "insert") or std.ascii.eqlIgnoreCase(name, "ins")) return win.VK_INSERT;
    if (std.ascii.eqlIgnoreCase(name, "capslock") or std.ascii.eqlIgnoreCase(name, "caps")) return win.VK_CAPITAL;
    if (std.ascii.eqlIgnoreCase(name, "printscreen") or std.ascii.eqlIgnoreCase(name, "prtsc")) return win.VK_SNAPSHOT;
    if (std.ascii.eqlIgnoreCase(name, "pause")) return win.VK_PAUSE;

    // Arrow keys
    if (std.ascii.eqlIgnoreCase(name, "up")) return win.VK_UP;
    if (std.ascii.eqlIgnoreCase(name, "down")) return win.VK_DOWN;
    if (std.ascii.eqlIgnoreCase(name, "left")) return win.VK_LEFT;
    if (std.ascii.eqlIgnoreCase(name, "right")) return win.VK_RIGHT;

    // Function keys
    if (std.ascii.eqlIgnoreCase(name, "f1")) return win.VK_F1;
    if (std.ascii.eqlIgnoreCase(name, "f2")) return win.VK_F2;
    if (std.ascii.eqlIgnoreCase(name, "f3")) return win.VK_F3;
    if (std.ascii.eqlIgnoreCase(name, "f4")) return win.VK_F4;
    if (std.ascii.eqlIgnoreCase(name, "f5")) return win.VK_F5;
    if (std.ascii.eqlIgnoreCase(name, "f6")) return win.VK_F6;
    if (std.ascii.eqlIgnoreCase(name, "f7")) return win.VK_F7;
    if (std.ascii.eqlIgnoreCase(name, "f8")) return win.VK_F8;
    if (std.ascii.eqlIgnoreCase(name, "f9")) return win.VK_F9;
    if (std.ascii.eqlIgnoreCase(name, "f10")) return win.VK_F10;
    if (std.ascii.eqlIgnoreCase(name, "f11")) return win.VK_F11;
    if (std.ascii.eqlIgnoreCase(name, "f12")) return win.VK_F12;

    // Single character (a-z, 0-9)
    if (name.len == 1) {
        const c = std.ascii.toUpper(name[0]);
        if (c >= 'A' and c <= 'Z') return @intCast(c);
        if (c >= '0' and c <= '9') return @intCast(c);
    }

    return null;
}
