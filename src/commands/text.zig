const std = @import("std");
const win = @import("../utils/windows.zig");

/// Type text character by character
pub fn typeText(text: []const u8) !void {
    for (text) |char| {
        // Handle special characters
        const needs_shift = isShiftChar(char);
        const vk = charToVk(char);

        if (vk == 0) continue; // Skip unsupported characters

        var input_count: u32 = 0;
        var inputs: [4]win.INPUT = undefined;

        // Press shift if needed
        if (needs_shift) {
            inputs[input_count] = win.INPUT{
                .type = win.INPUT_KEYBOARD,
                .u = .{ .ki = .{ .wVk = win.VK_SHIFT } },
            };
            input_count += 1;
        }

        // Key down
        inputs[input_count] = win.INPUT{
            .type = win.INPUT_KEYBOARD,
            .u = .{ .ki = .{ .wVk = vk } },
        };
        input_count += 1;

        // Key up
        inputs[input_count] = win.INPUT{
            .type = win.INPUT_KEYBOARD,
            .u = .{ .ki = .{ .wVk = vk, .dwFlags = win.KEYEVENTF_KEYUP } },
        };
        input_count += 1;

        // Release shift if needed
        if (needs_shift) {
            inputs[input_count] = win.INPUT{
                .type = win.INPUT_KEYBOARD,
                .u = .{ .ki = .{ .wVk = win.VK_SHIFT, .dwFlags = win.KEYEVENTF_KEYUP } },
            };
            input_count += 1;
        }

        // Send the inputs for this character
        const sent = win.SendInput(
            input_count,
            &inputs,
            @sizeOf(win.INPUT),
        );

        if (sent != input_count) {
            return error.SendInputFailed;
        }

        // Small delay between characters for reliability
        win.Sleep(10);
    }
}

fn isShiftChar(char: u8) bool {
    return switch (char) {
        'A'...'Z', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '{', '}', '|', ':', '"', '<', '>', '?', '~' => true,
        else => false,
    };
}

fn charToVk(char: u8) u16 {
    return switch (char) {
        'a'...'z' => @as(u16, std.ascii.toUpper(char)),
        'A'...'Z' => @as(u16, char),
        '0'...'9' => @as(u16, char),
        ' ' => win.VK_SPACE,
        '\n', '\r' => win.VK_RETURN,
        '\t' => win.VK_TAB,

        // Special characters (without shift)
        '`' => 0xC0, // VK_OEM_3
        '-' => 0xBD, // VK_OEM_MINUS
        '=' => 0xBB, // VK_OEM_PLUS
        '[' => 0xDB, // VK_OEM_4
        ']' => 0xDD, // VK_OEM_6
        '\\' => 0xDC, // VK_OEM_5
        ';' => 0xBA, // VK_OEM_1
        '\'' => 0xDE, // VK_OEM_7
        ',' => 0xBC, // VK_OEM_COMMA
        '.' => 0xBE, // VK_OEM_PERIOD
        '/' => 0xBF, // VK_OEM_2

        // Special characters (with shift) - use same VK codes
        '~' => 0xC0,
        '!' => '1',
        '@' => '2',
        '#' => '3',
        '$' => '4',
        '%' => '5',
        '^' => '6',
        '&' => '7',
        '*' => '8',
        '(' => '9',
        ')' => '0',
        '_' => 0xBD,
        '+' => 0xBB,
        '{' => 0xDB,
        '}' => 0xDD,
        '|' => 0xDC,
        ':' => 0xBA,
        '"' => 0xDE,
        '<' => 0xBC,
        '>' => 0xBE,
        '?' => 0xBF,

        else => 0, // Unsupported character
    };
}
