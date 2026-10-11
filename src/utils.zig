const std = @import("std");
const win = @import("utils/windows.zig");
const cli = @import("utils/cli.zig");
const app_cmd = @import("commands/app.zig");
const window_cmd = @import("commands/window.zig");
const mouse_cmd = @import("commands/mouse.zig");
const keyboard_cmd = @import("commands/keyboard.zig");
const screenshot_cmd = @import("commands/screenshot.zig");

const VALID_COMMANDS = [_][]const u8{ "mouse", "window", "app", "screenshot", "sleep", "key", "keyboard", "batch", "json", "run", "help", "--help", "-h", "version", "--version", "-v" };
const MOUSE_ACTIONS = [_][]const u8{ "move", "click", "scroll", "pos", "getpos" };
const WINDOW_ACTIONS = [_][]const u8{ "list", "focus", "move", "info", "scroll" };
const APP_ACTIONS = [_][]const u8{ "open", "close", "list" };

// Command Dispatcher and Batch Execution

pub fn tokenizeLine(allocator: std.mem.Allocator, line: []const u8) ![][]const u8 {
    var tokens: std.ArrayList([]const u8) = .empty;
    var i: usize = 0;
    while (i < line.len) {
        while (i < line.len and (line[i] == ' ' or line[i] == '\t')) : (i += 1) {}
        if (i >= line.len) break;

        if (line[i] == '"' or line[i] == '\'') {
            const quote = line[i];
            i += 1;
            const start = i;
            while (i < line.len and line[i] != quote) : (i += 1) {}
            const token = line[start..i];
            try tokens.append(allocator, token);
            if (i < line.len) i += 1;
        } else {
            const start = i;
            while (i < line.len and line[i] != ' ' and line[i] != '\t') : (i += 1) {}
            try tokens.append(allocator, line[start..i]);
        }
    }
    return tokens.toOwnedSlice(allocator);
}

fn jsonGetInt(val: std.json.Value) ?i32 {
    switch (val) {
        .integer => |i| return @intCast(i),
        .string => |s| return std.fmt.parseInt(i32, s, 10) catch null,
        else => return null,
    }
}

fn jsonGetBool(val: std.json.Value) bool {
    switch (val) {
        .bool => |b| return b,
        .string => |s| return std.ascii.eqlIgnoreCase(s, "true"),
        else => return false,
    }
}

fn executeJsonObject(allocator: std.mem.Allocator, obj: std.json.ObjectMap) anyerror!void {
    const cmd_val = obj.get("command") orelse obj.get("type") orelse {
        std.debug.print("Object missing 'command' field\n", .{});
        return error.MissingCommand;
    };
    const cmd = switch (cmd_val) {
        .string => |s| s,
        else => return error.InvalidCommandType,
    };

    if (std.mem.eql(u8, cmd, "mouse")) {
        const action = if (obj.get("action")) |a| switch (a) {
            .string => |s| s,
            else => "move",
        } else "move";

        if (std.mem.eql(u8, action, "move")) {
            const x = jsonGetInt(obj.get("x") orelse return error.MissingCoordinate) orelse return error.InvalidCoordinate;
            const y = jsonGetInt(obj.get("y") orelse return error.MissingCoordinate) orelse return error.InvalidCoordinate;
            try mouse_cmd.mouseMove(x, y);
        } else if (std.mem.eql(u8, action, "click")) {
            const button = if (obj.get("button")) |b| switch (b) {
                .string => |s| s,
                else => "left",
            } else "left";
            mouse_cmd.mouseClick(button);
        } else if (std.mem.eql(u8, action, "scroll")) {
            const delta = jsonGetInt(obj.get("delta") orelse return error.MissingDelta) orelse return error.InvalidDelta;
            mouse_cmd.mouseScroll(delta);
        } else if (std.mem.eql(u8, action, "pos")) {
            const pos = try mouse_cmd.mouseGetPos();
            std.debug.print("mouse pos: x={d}, y={d}\n", .{ pos.x, pos.y });
        }
    } else if (std.mem.eql(u8, cmd, "sleep")) {
        const ms_i = if (obj.get("ms")) |m| jsonGetInt(m) orelse 1000 else 1000;
        win.Sleep(@intCast(ms_i));
    } else if (std.mem.eql(u8, cmd, "key")) {
        const combo_val = obj.get("combo") orelse obj.get("keys") orelse return error.MissingKeyCombo;
        const combo = switch (combo_val) {
            .string => |s| s,
            else => return error.InvalidKeyCombo,
        };
        try keyboard_cmd.sendKeyCombo(combo);
    } else if (std.mem.eql(u8, cmd, "window")) {
        const action = if (obj.get("action")) |a| switch (a) {
            .string => |s| s,
            else => "focus",
        } else "focus";

        if (std.mem.eql(u8, action, "list")) {
            window_cmd.listWindows(allocator);
        } else if (std.mem.eql(u8, action, "focus")) {
            const title_val = obj.get("title") orelse return error.MissingWindowTitle;
            const title = switch (title_val) {
                .string => |s| s,
                else => return error.InvalidWindowTitle,
            };
            try window_cmd.focusWindow(allocator, title);
        } else if (std.mem.eql(u8, action, "move")) {
            const title_val = obj.get("title") orelse return error.MissingWindowTitle;
            const title = switch (title_val) {
                .string => |s| s,
                else => return error.InvalidWindowTitle,
            };
            const x = if (obj.get("x")) |v| jsonGetInt(v) else null;
            const y = if (obj.get("y")) |v| jsonGetInt(v) else null;
            const w = if (obj.get("w") orelse obj.get("width")) |v| jsonGetInt(v) else null;
            const h = if (obj.get("h") orelse obj.get("height")) |v| jsonGetInt(v) else null;
            try window_cmd.moveWindow(allocator, title, x, y, w, h);
        } else if (std.mem.eql(u8, action, "info")) {
            const title_val = obj.get("title") orelse return error.MissingWindowTitle;
            const title = switch (title_val) {
                .string => |s| s,
                else => return error.InvalidWindowTitle,
            };
            try window_cmd.getWindowInfo(allocator, title);
        } else if (std.mem.eql(u8, action, "scroll")) {
            const title_val = obj.get("title") orelse return error.MissingWindowTitle;
            const title = switch (title_val) {
                .string => |s| s,
                else => return error.InvalidWindowTitle,
            };
            const delta = jsonGetInt(obj.get("delta") orelse return error.MissingDelta) orelse return error.InvalidDelta;
            try window_cmd.scrollWindow(allocator, title, delta);
        }
    } else if (std.mem.eql(u8, cmd, "screenshot")) {
        var options = screenshot_cmd.ScreenshotOptions{};
        if (obj.get("filename")) |fn_val| {
            options.filename = switch (fn_val) {
                .string => |s| s,
                else => null,
            };
        }
        if (obj.get("clipboard")) |c_val| {
            options.to_clipboard = jsonGetBool(c_val);
        }
        if (obj.get("x")) |xv| options.x = jsonGetInt(xv) orelse 0;
        if (obj.get("y")) |yv| options.y = jsonGetInt(yv) orelse 0;
        if (obj.get("w") orelse obj.get("width")) |wv| options.width = jsonGetInt(wv);
        if (obj.get("h") orelse obj.get("height")) |hv| options.height = jsonGetInt(hv);
        try screenshot_cmd.takeScreenshot(allocator, options);
    } else if (std.mem.eql(u8, cmd, "app")) {
        const action = if (obj.get("action")) |a| switch (a) {
            .string => |s| s,
            else => "open",
        } else "open";
        if (std.mem.eql(u8, action, "open")) {
            const name = if (obj.get("name") orelse obj.get("app")) |v| switch (v) {
                .string => |s| s,
                else => return error.MissingAppName,
            } else return error.MissingAppName;
            try app_cmd.openApp(allocator, name);
        } else if (std.mem.eql(u8, action, "close")) {
            const name = if (obj.get("name") orelse obj.get("app")) |v| switch (v) {
                .string => |s| s,
                else => return error.MissingAppName,
            } else return error.MissingAppName;
            try app_cmd.closeApp(allocator, name);
        } else if (std.mem.eql(u8, action, "list")) {
            const running = if (obj.get("running")) |v| jsonGetBool(v) else false;
            if (running) {
                try app_cmd.listRunningApps(allocator);
            } else {
                try app_cmd.listInstalledApps(allocator);
            }
        }
    } else {
        std.debug.print("Unknown command: {s}\n", .{cmd});
    }
}

pub fn executeBatch(allocator: std.mem.Allocator, input: []const u8) anyerror!void {
    const content = if (std.fs.cwd().openFile(input, .{})) |file| blk: {
        defer file.close();
        const max_size = 10 * 1024 * 1024;
        break :blk try file.readToEndAlloc(allocator, max_size);
    } else |_| blk: {
        break :blk try allocator.dupe(u8, input);
    };
    defer allocator.free(content);

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, content, .{}) catch |err| {
        std.debug.print("Failed to parse JSON instructions: {any}\n", .{err});
        return err;
    };
    defer parsed.deinit();

    const items = switch (parsed.value) {
        .array => |arr| arr.items,
        .object => |obj| blk: {
            if (obj.get("actions")) |act| {
                if (act == .array) break :blk act.array.items;
            }
            if (obj.get("steps")) |st| {
                if (st == .array) break :blk st.array.items;
            }
            if (obj.get("commands")) |cmd| {
                if (cmd == .array) break :blk cmd.array.items;
            }
            std.debug.print("JSON object must contain an 'actions', 'steps', or 'commands' array\n", .{});
            return error.InvalidJsonSchema;
        },
        else => {
            std.debug.print("JSON instructions must be an array or an object with an 'actions' array\n", .{});
            return error.InvalidJsonSchema;
        },
    };

    std.debug.print("Executing batch of {d} instructions...\n", .{items.len});

    for (items, 0..) |item, idx| {
        std.debug.print("[{d}/{d}] ", .{ idx + 1, items.len });
        switch (item) {
            .string => |str| {
                std.debug.print("{s}\n", .{str});
                const tokens = try tokenizeLine(allocator, str);
                defer allocator.free(tokens);
                try executeCommand(allocator, tokens);
            },
            .object => |obj| {
                try executeJsonObject(allocator, obj);
            },
            else => {
                std.debug.print("Skipping unrecognized instruction type\n", .{});
            },
        }
    }

    std.debug.print("Batch execution completed successfully.\n", .{});
}

pub fn executeCommand(allocator: std.mem.Allocator, args: []const []const u8) anyerror!void {
    if (args.len == 0) {
        cli.printHelp();
        return;
    }

    const group = args[0];

    // Handle help flags
    if (std.mem.eql(u8, group, "help") or std.mem.eql(u8, group, "--help") or std.mem.eql(u8, group, "-h")) {
        if (args.len >= 2) {
            const cmd = args[1];
            if (std.mem.eql(u8, cmd, "mouse")) {
                cli.printMouseHelp();
            } else if (std.mem.eql(u8, cmd, "window")) {
                cli.printWindowHelp();
            } else if (std.mem.eql(u8, cmd, "app")) {
                cli.printAppHelp();
            } else if (std.mem.eql(u8, cmd, "screenshot")) {
                cli.printScreenshotHelp();
            } else if (std.mem.eql(u8, cmd, "key") or std.mem.eql(u8, cmd, "keyboard")) {
                cli.printKeyHelp();
            } else {
                try cli.printCommandError(allocator, cmd, &VALID_COMMANDS);
            }
        } else {
            cli.printHelp();
        }
        return;
    }

    // Handle version flags
    if (std.mem.eql(u8, group, "version") or std.mem.eql(u8, group, "--version") or std.mem.eql(u8, group, "-v")) {
        cli.printVersion();
        return;
    }

    if (std.mem.eql(u8, group, "mouse")) {
        if (args.len < 2) {
            cli.printMouseHelp();
            return;
        }
        const action = args[1];

        // Check for help
        if (std.mem.eql(u8, action, "--help") or std.mem.eql(u8, action, "-h")) {
            cli.printMouseHelp();
            return;
        }

        if (std.mem.eql(u8, action, "move")) {
            if (args.len < 4) {
                std.debug.print("Error: 'move' requires x and y coordinates\n", .{});
                std.debug.print("Usage: windotool mouse move <x> <y>\n\n", .{});
                cli.printMouseHelp();
                return;
            }
            const x = std.fmt.parseInt(i32, args[2], 10) catch |err| {
                std.debug.print("Error: invalid x coordinate '{s}': {any}\n", .{ args[2], err });
                return;
            };
            const y = std.fmt.parseInt(i32, args[3], 10) catch |err| {
                std.debug.print("Error: invalid y coordinate '{s}': {any}\n", .{ args[3], err });
                return;
            };
            mouse_cmd.mouseMove(x, y) catch |err| {
                std.debug.print("Error: failed to move mouse: {any}\n", .{err});
                return;
            };
        } else if (std.mem.eql(u8, action, "click")) {
            const button = if (args.len >= 3) args[2] else "left";
            mouse_cmd.mouseClick(button);
        } else if (std.mem.eql(u8, action, "scroll")) {
            if (args.len < 3) {
                std.debug.print("Error: 'scroll' requires delta value\n", .{});
                std.debug.print("Usage: windotool mouse scroll <delta>\n\n", .{});
                cli.printMouseHelp();
                return;
            }
            const delta = std.fmt.parseInt(i32, args[2], 10) catch |err| {
                std.debug.print("Error: invalid scroll delta '{s}': {any}\n", .{ args[2], err });
                return;
            };
            mouse_cmd.mouseScroll(delta);
        } else if (std.mem.eql(u8, action, "pos") or std.mem.eql(u8, action, "getpos")) {
            const pos = mouse_cmd.mouseGetPos() catch |err| {
                std.debug.print("Error: failed to get cursor position: {any}\n", .{err});
                return;
            };
            std.debug.print("Cursor position: x={d}, y={d}\n", .{ pos.x, pos.y });
        } else {
            try cli.printActionError(allocator, "mouse", action, &MOUSE_ACTIONS);
        }
    } else if (std.mem.eql(u8, group, "app")) {
        if (args.len < 2) {
            cli.printAppHelp();
            return;
        }
        const action = args[1];

        if (std.mem.eql(u8, action, "--help") or std.mem.eql(u8, action, "-h")) {
            cli.printAppHelp();
            return;
        }

        if (std.mem.eql(u8, action, "open")) {
            if (args.len < 3) {
                std.debug.print("Error: 'open' requires application name or path\n", .{});
                std.debug.print("Usage: windotool app open <app-name>\n\n", .{});
                cli.printAppHelp();
                return;
            }
            app_cmd.openApp(allocator, args[2]) catch |err| {
                std.debug.print("Error: failed to open application: {any}\n", .{err});
                return;
            };
        } else if (std.mem.eql(u8, action, "close")) {
            if (args.len < 3) {
                std.debug.print("Error: 'close' requires application name\n", .{});
                std.debug.print("Usage: windotool app close <app-name>\n\n", .{});
                cli.printAppHelp();
                return;
            }
            app_cmd.closeApp(allocator, args[2]) catch |err| {
                std.debug.print("Error: failed to close application: {any}\n", .{err});
                return;
            };
        } else if (std.mem.eql(u8, action, "list")) {
            if (args.len >= 3 and std.mem.eql(u8, args[2], "--running")) {
                app_cmd.listRunningApps(allocator) catch |err| {
                    std.debug.print("Error: failed to list running apps: {any}\n", .{err});
                    return;
                };
            } else {
                app_cmd.listInstalledApps(allocator) catch |err| {
                    std.debug.print("Error: failed to list installed apps: {any}\n", .{err});
                    return;
                };
            }
        } else {
            try cli.printActionError(allocator, "app", action, &APP_ACTIONS);
        }
    } else if (std.mem.eql(u8, group, "window")) {
        if (args.len < 2) {
            cli.printWindowHelp();
            return;
        }
        const action = args[1];

        if (std.mem.eql(u8, action, "--help") or std.mem.eql(u8, action, "-h")) {
            cli.printWindowHelp();
            return;
        }

        if (std.mem.eql(u8, action, "list")) {
            window_cmd.listWindows(allocator);
        } else if (std.mem.eql(u8, action, "focus")) {
            var title: ?[]const u8 = null;
            var i: usize = 2;
            while (i < args.len) : (i += 1) {
                if (std.mem.eql(u8, args[i], "--title") or std.mem.eql(u8, args[i], "-t")) {
                    i += 1;
                    if (i < args.len) title = args[i];
                } else if (!std.mem.startsWith(u8, args[i], "-") and title == null) {
                    title = args[i];
                }
            }
            const t = title orelse {
                std.debug.print("Error: 'focus' requires --title argument\n", .{});
                std.debug.print("Usage: windotool window focus --title <query>\n\n", .{});
                cli.printWindowHelp();
                return;
            };
            window_cmd.focusWindow(allocator, t) catch |err| {
                std.debug.print("Error: failed to focus window: {any}\n", .{err});
                return;
            };
        } else if (std.mem.eql(u8, action, "move")) {
            var title: ?[]const u8 = null;
            var x: ?i32 = null;
            var y: ?i32 = null;
            var w: ?i32 = null;
            var h: ?i32 = null;
            var i: usize = 2;
            while (i < args.len) : (i += 1) {
                if (std.mem.eql(u8, args[i], "--title") or std.mem.eql(u8, args[i], "-t")) {
                    i += 1;
                    if (i < args.len) title = args[i];
                } else if (std.mem.eql(u8, args[i], "--x") or std.mem.eql(u8, args[i], "-x")) {
                    i += 1;
                    if (i < args.len) x = std.fmt.parseInt(i32, args[i], 10) catch null;
                } else if (std.mem.eql(u8, args[i], "--y") or std.mem.eql(u8, args[i], "-y")) {
                    i += 1;
                    if (i < args.len) y = std.fmt.parseInt(i32, args[i], 10) catch null;
                } else if (std.mem.eql(u8, args[i], "--w") or std.mem.eql(u8, args[i], "-w") or std.mem.eql(u8, args[i], "--width")) {
                    i += 1;
                    if (i < args.len) w = std.fmt.parseInt(i32, args[i], 10) catch null;
                } else if (std.mem.eql(u8, args[i], "--h") or std.mem.eql(u8, args[i], "-h") or std.mem.eql(u8, args[i], "--height")) {
                    i += 1;
                    if (i < args.len) h = std.fmt.parseInt(i32, args[i], 10) catch null;
                } else if (!std.mem.startsWith(u8, args[i], "-") and title == null) {
                    title = args[i];
                }
            }
            const t = title orelse {
                std.debug.print("Error: 'move' requires --title argument\n", .{});
                std.debug.print("Usage: windotool window move --title <query> [--x <x>] [--y <y>] [--w <w>] [--h <h>]\n\n", .{});
                cli.printWindowHelp();
                return;
            };
            window_cmd.moveWindow(allocator, t, x, y, w, h) catch |err| {
                std.debug.print("Error: failed to move window: {any}\n", .{err});
                return;
            };
        } else if (std.mem.eql(u8, action, "info")) {
            var title: ?[]const u8 = null;
            var i: usize = 2;
            while (i < args.len) : (i += 1) {
                if (std.mem.eql(u8, args[i], "--title") or std.mem.eql(u8, args[i], "-t")) {
                    i += 1;
                    if (i < args.len) title = args[i];
                } else if (!std.mem.startsWith(u8, args[i], "-") and title == null) {
                    title = args[i];
                }
            }
            const t = title orelse {
                std.debug.print("Error: 'info' requires --title argument\n", .{});
                std.debug.print("Usage: windotool window info --title <query>\n\n", .{});
                cli.printWindowHelp();
                return;
            };
            window_cmd.getWindowInfo(allocator, t) catch |err| {
                std.debug.print("Error: failed to get window info: {any}\n", .{err});
                return;
            };
        } else if (std.mem.eql(u8, action, "scroll")) {
            var title: ?[]const u8 = null;
            var delta: ?i32 = null;
            var i: usize = 2;
            while (i < args.len) : (i += 1) {
                if (std.mem.eql(u8, args[i], "--title") or std.mem.eql(u8, args[i], "-t")) {
                    i += 1;
                    if (i < args.len) title = args[i];
                } else if (std.mem.startsWith(u8, args[i], "-") and !std.mem.eql(u8, args[i], "-t") and !std.mem.eql(u8, args[i], "--title")) {
                    // This is a negative number
                    delta = std.fmt.parseInt(i32, args[i], 10) catch null;
                } else if (title == null) {
                    title = args[i];
                } else if (delta == null) {
                    delta = std.fmt.parseInt(i32, args[i], 10) catch null;
                }
            }
            const t = title orelse {
                std.debug.print("Error: 'scroll' requires --title and delta arguments\n", .{});
                std.debug.print("Usage: windotool window scroll --title <query> <delta>\n\n", .{});
                cli.printWindowHelp();
                return;
            };
            const d = delta orelse {
                std.debug.print("Error: 'scroll' requires delta value (e.g., 120 for up, -120 for down)\n", .{});
                std.debug.print("Usage: windotool window scroll --title <query> <delta>\n\n", .{});
                cli.printWindowHelp();
                return;
            };
            window_cmd.scrollWindow(allocator, t, d) catch |err| {
                std.debug.print("Error: failed to scroll window: {any}\n", .{err});
                return;
            };
        } else {
            try cli.printActionError(allocator, "window", action, &WINDOW_ACTIONS);
        }
    } else if (std.mem.eql(u8, group, "sleep")) {
        if (args.len < 2) {
            std.debug.print("Error: 'sleep' requires milliseconds value\n", .{});
            std.debug.print("Usage: windotool sleep <milliseconds>\n", .{});
            return;
        }
        const ms = std.fmt.parseInt(u32, args[1], 10) catch |err| {
            std.debug.print("Error: invalid milliseconds value '{s}': {any}\n", .{ args[1], err });
            return;
        };
        win.Sleep(ms);
    } else if (std.mem.eql(u8, group, "key") or std.mem.eql(u8, group, "keyboard")) {
        if (args.len < 2 or std.mem.eql(u8, args[1], "--help") or std.mem.eql(u8, args[1], "-h")) {
            cli.printKeyHelp();
            return;
        }
        keyboard_cmd.sendKeyCombo(args[1]) catch |err| {
            std.debug.print("Error: failed to send key combination: {any}\n", .{err});
            return;
        };
    } else if (std.mem.eql(u8, group, "screenshot")) {
        var options = screenshot_cmd.ScreenshotOptions{};
        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            if (std.mem.eql(u8, args[i], "-c") or std.mem.eql(u8, args[i], "--clipboard")) {
                options.to_clipboard = true;
            } else if (std.mem.eql(u8, args[i], "-o") or std.mem.eql(u8, args[i], "--output")) {
                i += 1;
                if (i < args.len) options.filename = args[i];
            } else if (std.mem.eql(u8, args[i], "-r") or std.mem.eql(u8, args[i], "--region")) {
                if (i + 4 < args.len) {
                    options.x = std.fmt.parseInt(i32, args[i + 1], 10) catch 0;
                    options.y = std.fmt.parseInt(i32, args[i + 2], 10) catch 0;
                    options.width = std.fmt.parseInt(i32, args[i + 3], 10) catch null;
                    options.height = std.fmt.parseInt(i32, args[i + 4], 10) catch null;
                    i += 4;
                }
            } else if (!std.mem.startsWith(u8, args[i], "-") and options.filename == null) {
                options.filename = args[i];
            }
        }
        screenshot_cmd.takeScreenshot(allocator, options) catch |err| {
            std.debug.print("Error: failed to take screenshot: {any}\n", .{err});
            return;
        };
    } else if (std.mem.eql(u8, group, "batch") or std.mem.eql(u8, group, "json") or std.mem.eql(u8, group, "run")) {
        if (args.len < 2) {
            std.debug.print("Error: batch command requires JSON file or content\n", .{});
            std.debug.print("Usage: windotool batch <file.json | '[\"command1\", ...]'>\n", .{});
            return;
        }
        executeBatch(allocator, args[1]) catch |err| {
            std.debug.print("Error: failed to execute batch: {any}\n", .{err});
            return;
        };
    } else {
        try cli.printCommandError(allocator, group, &VALID_COMMANDS);
    }
}
