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
        \\  window      Manage windows (list, focus, move, resize, minimize, maximize)
        \\  app         Launch, close, and list applications
        \\  screenshot  Capture screenshots to file or clipboard
        \\  text        Type text into active window
        \\  clipboard   Get, set, or clear clipboard content
        \\  file        File operations (read, write, list, copy, move, etc.)
        \\  system      System information and utilities
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
        \\Manage windows (list, focus, move, resize, minimize, maximize).
        \\
        \\Available Actions:
        \\  list                                List all visible windows
        \\  focus --title <query>              Focus window matching title
        \\  move --title <query> [options]     Move/resize window
        \\  info --title <query>               Get detailed window information
        \\  scroll --title <query> <delta>     Scroll window content
        \\  minimize --title <query>           Minimize window
        \\  maximize --title <query>           Maximize window
        \\  restore --title <query>            Restore minimized/maximized window
        \\  active                             Get title of active window
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
        \\  windotool window minimize --title "Chrome"
        \\  windotool window maximize --title "Notepad"
        \\  windotool window restore --title "Chrome"
        \\  windotool window active
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

pub fn printTextHelp() void {
    std.debug.print(
        \\Usage: windotool text <action> [arguments]
        \\
        \\Type text into the active window.
        \\
        \\Available Actions:
        \\  type <text>    Type the specified text character by character
        \\
        \\Examples:
        \\  windotool text type "Hello, World!"
        \\  windotool text type "user@example.com"
        \\
        \\Note: The text will be typed into the currently active/focused window.
        \\      Use special characters and spaces normally.
        \\
    , .{});
}

pub fn printClipboardHelp() void {
    std.debug.print(
        \\Usage: windotool clipboard <action> [arguments]
        \\
        \\Get, set, or clear clipboard content.
        \\
        \\Available Actions:
        \\  get              Get current clipboard text content
        \\  set <text>       Set clipboard to specified text
        \\  clear            Clear clipboard content
        \\
        \\Examples:
        \\  windotool clipboard get
        \\  windotool clipboard set "Hello, World!"
        \\  windotool clipboard clear
        \\
        \\Alias: 'clip' can be used instead of 'clipboard'
        \\  windotool clip get
        \\  windotool clip set "Copy this"
        \\
    , .{});
}

pub fn printFileHelp() void {
    std.debug.print(
        \\Usage: windotool file <action> [arguments]
        \\
        \\File operations for reading, writing, and managing files.
        \\
        \\Available Actions:
        \\  read <path>                  Read file contents
        \\  write <path> <content>       Write content to file (overwrites)
        \\  append <path> <content>      Append content to file
        \\  exists <path>                Check if file/directory exists
        \\  delete <path>                Delete file or directory
        \\  size <path>                  Get file size in bytes
        \\  list <directory>             List files in directory
        \\  mkdir <path>                 Create directory
        \\  copy <source> <destination>  Copy file
        \\  move <source> <destination>  Move/rename file
        \\
        \\Examples:
        \\  windotool file read "C:\\data.txt"
        \\  windotool file write "C:\\output.txt" "Hello, World!"
        \\  windotool file append "C:\\log.txt" "New log entry"
        \\  windotool file exists "C:\\temp"
        \\  windotool file delete "C:\\old.txt"
        \\  windotool file size "C:\\document.pdf"
        \\  windotool file list "C:\\Users"
        \\  windotool file mkdir "C:\\new_folder"
        \\  windotool file copy "C:\\source.txt" "C:\\backup.txt"
        \\  windotool file move "C:\\old_name.txt" "C:\\new_name.txt"
        \\
    , .{});
}

pub fn printSystemHelp() void {
    std.debug.print(
        \\Usage: windotool system <action> [arguments]
        \\
        \\System information and utilities.
        \\
        \\Available Actions:
        \\  screen                     Get screen width and height
        \\  active                     Get active window title
        \\  pixel <x> <y>              Get pixel color at coordinates (RGB hex)
        \\  wait <milliseconds>        Wait/sleep for specified duration
        \\  time                       Get current system time
        \\  process <name>             Check if process is running
        \\  env <variable>             Get environment variable value
        \\
        \\Examples:
        \\  windotool system screen
        \\  windotool system active
        \\  windotool system pixel 100 200
        \\  windotool system wait 1000
        \\  windotool system time
        \\  windotool system process "chrome.exe"
        \\  windotool system env "PATH"
        \\
        \\Alias: 'sys' can be used instead of 'system'
        \\  windotool sys screen
        \\  windotool sys time
        \\
    , .{});
}
