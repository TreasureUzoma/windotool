const std = @import("std");

/// Calculate Levenshtein distance between two strings (for "did you mean" suggestions)
pub fn levenshteinDistance(allocator: std.mem.Allocator, s1: []const u8, s2: []const u8) !usize {
    const len1 = s1.len;
    const len2 = s2.len;

    if (len1 == 0) return len2;
    if (len2 == 0) return len1;

    var matrix = try allocator.alloc([]usize, len1 + 1);
    defer allocator.free(matrix);

    for (0..len1 + 1) |i| {
        matrix[i] = try allocator.alloc(usize, len2 + 1);
    }
    defer for (0..len1 + 1) |i| {
        allocator.free(matrix[i]);
    };

    for (0..len1 + 1) |i| {
        matrix[i][0] = i;
    }
    for (0..len2 + 1) |j| {
        matrix[0][j] = j;
    }

    for (1..len1 + 1) |i| {
        for (1..len2 + 1) |j| {
            const cost: usize = if (std.ascii.toLower(s1[i - 1]) == std.ascii.toLower(s2[j - 1])) 0 else 1;

            const deletion = matrix[i - 1][j] + 1;
            const insertion = matrix[i][j - 1] + 1;
            const substitution = matrix[i - 1][j - 1] + cost;

            matrix[i][j] = @min(deletion, @min(insertion, substitution));
        }
    }

    return matrix[len1][len2];
}

/// Find the closest match for a command
pub fn findClosestCommand(allocator: std.mem.Allocator, input: []const u8, commands: []const []const u8) !?[]const u8 {
    var min_distance: usize = std.math.maxInt(usize);
    var closest: ?[]const u8 = null;

    for (commands) |cmd| {
        const distance = try levenshteinDistance(allocator, input, cmd);
        if (distance < min_distance and distance <= 2) { // Only suggest if within 2 edits
            min_distance = distance;
            closest = cmd;
        }
    }

    return closest;
}

/// Print error message with optional suggestion
pub fn printCommandError(allocator: std.mem.Allocator, command: []const u8, valid_commands: []const []const u8) !void {
    std.debug.print("Error: unknown command \"{s}\"\n", .{command});

    const suggestion = try findClosestCommand(allocator, command, valid_commands);
    if (suggestion) |suggested| {
        std.debug.print("\nDid you mean this?\n    {s}\n", .{suggested});
    }

    std.debug.print("\nRun 'windotool --help' for usage.\n", .{});
}

/// Print error message for invalid action
pub fn printActionError(allocator: std.mem.Allocator, command: []const u8, action: []const u8, valid_actions: []const []const u8) !void {
    std.debug.print("Error: unknown action \"{s}\" for \"{s}\"\n", .{ action, command });

    const suggestion = try findClosestCommand(allocator, action, valid_actions);
    if (suggestion) |suggested| {
        std.debug.print("\nDid you mean this?\n    {s}\n", .{suggested});
    }

    std.debug.print("\nRun 'windotool {s} --help' for usage.\n", .{command});
}

pub fn printHelp() void {
    std.debug.print(
        \\Windotool — Native Windows automation CLI
        \\
        \\Windotool helps you automate Windows tasks from the command line.
        \\It provides commands for controlling windows, mouse, keyboard, and more.
        \\
        \\Examples:
        \\  windotool mouse move 100 200
        \\  windotool window focus --title "Chrome"
        \\  windotool key ctrl+c
        \\  windotool screenshot output.png
        \\
        \\Usage:
        \\  windotool [command]
        \\
        \\Available Commands:
        \\  mouse       Control mouse movement, clicks, and scrolling
        \\  keyboard    Simulate keyboard input and key combinations
        \\  window      Manage windows (list, focus, move, resize)
        \\  app         Launch, close, and list applications
        \\  screenshot  Capture screenshots to file or clipboard
        \\  sleep       Pause execution for specified milliseconds
        \\  key         Send key combinations (alias for keyboard)
        \\  batch       Execute batch commands from JSON file
        \\  json        Execute JSON command sequences (alias for batch)
        \\  help        Display this help message
        \\
        \\Flags:
        \\  -h, --help     Display help for windotool
        \\  -v, --version  Display version information
        \\
        \\Use "windotool [command] --help" for more information about a command.
        \\
    , .{});
}

pub fn printVersion() void {
    std.debug.print("windotool version 0.1.0\n", .{});
}

pub fn printMouseHelp() void {
    std.debug.print(
        \\Usage: windotool mouse <action> [arguments]
        \\
        \\Control mouse movement, clicks, and scrolling.
        \\
        \\Available Actions:
        \\  move <x> <y>              Move cursor to position (x, y)
        \\  click [button]            Click mouse button (left|right|middle|double)
        \\  scroll <delta>            Scroll by delta amount (positive=up, negative=down)
        \\  pos                       Get current cursor position
        \\
        \\Examples:
        \\  windotool mouse move 500 300
        \\  windotool mouse click left
        \\  windotool mouse scroll 120
        \\  windotool mouse pos
        \\
    , .{});
}

pub fn printWindowHelp() void {
    std.debug.print(
        \\Usage: windotool window <action> [arguments]
        \\
        \\Manage windows (list, focus, move, resize).
        \\
        \\Available Actions:
        \\  list                                List all visible windows
        \\  focus --title <query>              Focus window matching title
        \\  move --title <query> [options]     Move/resize window
        \\  info --title <query>               Get detailed window information
        \\  scroll --title <query> <delta>     Scroll window content
        \\
        \\Move Options:
        \\  --x <x>        Set window X position
        \\  --y <y>        Set window Y position
        \\  --w <width>    Set window width
        \\  --h <height>   Set window height
        \\
        \\Examples:
        \\  windotool window list
        \\  windotool window focus --title "Chrome"
        \\  windotool window move --title "Notepad" --x 100 --y 100 --w 800 --h 600
        \\  windotool window info --title "Chrome"
        \\  windotool window scroll --title "Chrome" 120
        \\
    , .{});
}

pub fn printAppHelp() void {
    std.debug.print(
        \\Usage: windotool app <action> [arguments]
        \\
        \\Launch, close, and list applications.
        \\
        \\Available Actions:
        \\  open <name>         Open application by name or path
        \\  close <name>        Close running application
        \\  list [--running]    List installed apps (or running with --running)
        \\
        \\Examples:
        \\  windotool app open notepad
        \\  windotool app open "C:\\Program Files\\App\\app.exe"
        \\  windotool app close notepad.exe
        \\  windotool app list
        \\  windotool app list --running
        \\
    , .{});
}

pub fn printScreenshotHelp() void {
    std.debug.print(
        \\Usage: windotool screenshot [options] [filename]
        \\
        \\Capture screenshots to file or clipboard.
        \\
        \\Options:
        \\  -c, --clipboard           Copy to clipboard
        \\  -o, --output <filename>   Save to file
        \\  -r, --region <x> <y> <w> <h>  Capture specific region
        \\
        \\Examples:
        \\  windotool screenshot                    # Auto-generated filename
        \\  windotool screenshot output.png         # Specific filename
        \\  windotool screenshot -c                 # To clipboard only
        \\  windotool screenshot -c output.png      # Both file and clipboard
        \\  windotool screenshot -r 0 0 800 600 capture.png
        \\
    , .{});
}

pub fn printKeyHelp() void {
    std.debug.print(
        \\Usage: windotool key <combination>
        \\
        \\Send key combinations (keyboard shortcuts).
        \\
        \\Format:
        \\  Keys separated by '+' (e.g., ctrl+c, alt+f4)
        \\
        \\Supported Keys:
        \\  - Modifiers: ctrl, alt, shift, win
        \\  - Special: enter, tab, esc, space, backspace, delete
        \\  - Navigation: home, end, pageup, pagedown, up, down, left, right
        \\  - Function: f1-f12
        \\  - Characters: a-z, 0-9
        \\
        \\Examples:
        \\  windotool key ctrl+c
        \\  windotool key alt+f4
        \\  windotool key ctrl+shift+esc
        \\  windotool key win+r
        \\
    , .{});
}
