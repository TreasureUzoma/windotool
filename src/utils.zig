const std = @import("std");
const win = @import("utils/windows.zig");
const cli = @import("utils/cli.zig");
const app_cmd = @import("commands/app.zig");
const window_cmd = @import("commands/window.zig");
const mouse_cmd = @import("commands/mouse.zig");
const keyboard_cmd = @import("commands/keyboard.zig");
const screenshot_cmd = @import("commands/screenshot.zig");
const text_cmd = @import("commands/text.zig");
const clipboard_cmd = @import("commands/clipboard.zig");
const file_cmd = @import("commands/file.zig");
const system_cmd = @import("commands/system.zig");

const VALID_COMMANDS = [_][]const u8{ "mouse", "window", "app", "screenshot", "sleep", "key", "keyboard", "batch", "json", "run", "text", "type", "clipboard", "clip", "file", "system", "help", "--help", "-h", "version", "--version", "-v" };
const MOUSE_ACTIONS = [_][]const u8{ "move", "click", "scroll", "pos", "getpos" };
const WINDOW_ACTIONS = [_][]const u8{ "list", "focus", "move", "info", "scroll", "minimize", "maximize", "restore", "active" };
const APP_ACTIONS = [_][]const u8{ "open", "close", "list" };
const CLIPBOARD_ACTIONS = [_][]const u8{ "get", "set", "clear" };
const FILE_ACTIONS = [_][]const u8{ "read", "write", "append", "exists", "delete", "size", "list", "mkdir", "copy", "move" };
const SYSTEM_ACTIONS = [_][]const u8{ "screen", "active", "pixel", "wait", "time", "running", "env" };

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
        } else if (std.mem.eql(u8, action, "minimize")) {
            const title_val = obj.get("title") orelse return error.MissingWindowTitle;
            const title = switch (title_val) {
                .string => |s| s,
                else => return error.InvalidWindowTitle,
            };
            try window_cmd.minimizeWindow(allocator, title);
        } else if (std.mem.eql(u8, action, "maximize")) {
            const title_val = obj.get("title") orelse return error.MissingWindowTitle;
            const title = switch (title_val) {
                .string => |s| s,
                else => return error.InvalidWindowTitle,
            };
            try window_cmd.maximizeWindow(allocator, title);
        } else if (std.mem.eql(u8, action, "restore")) {
            const title_val = obj.get("title") orelse return error.MissingWindowTitle;
            const title = switch (title_val) {
                .string => |s| s,
                else => return error.InvalidWindowTitle,
            };
            try window_cmd.restoreWindow(allocator, title);
        } else if (std.mem.eql(u8, action, "active")) {
            try window_cmd.getActiveWindow(allocator);
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
    } else if (std.mem.eql(u8, cmd, "text") or std.mem.eql(u8, cmd, "type")) {
        const action = if (obj.get("action")) |a| switch (a) {
            .string => |s| s,
            else => "type",
        } else "type";
        
        if (std.mem.eql(u8, action, "type")) {
            const text_val = obj.get("text") orelse obj.get("content") orelse return error.MissingText;
            const text = switch (text_val) {
                .string => |s| s,
                else => return error.InvalidText,
            };
            try text_cmd.typeText(text);
        }
    } else if (std.mem.eql(u8, cmd, "clipboard") or std.mem.eql(u8, cmd, "clip")) {
        const action = if (obj.get("action")) |a| switch (a) {
            .string => |s| s,
            else => "get",
        } else "get";
        
        if (std.mem.eql(u8, action, "get")) {
            const text = try clipboard_cmd.getText(allocator);
            defer allocator.free(text);
            std.debug.print("Clipboard: {s}\n", .{text});
        } else if (std.mem.eql(u8, action, "set")) {
            const text_val = obj.get("text") orelse obj.get("content") orelse return error.MissingText;
            const text = switch (text_val) {
                .string => |s| s,
                else => return error.InvalidText,
            };
            try clipboard_cmd.setText(allocator, text);
        } else if (std.mem.eql(u8, action, "clear")) {
            try clipboard_cmd.clear();
        }
    } else if (std.mem.eql(u8, cmd, "file")) {
        const action = if (obj.get("action")) |a| switch (a) {
            .string => |s| s,
            else => return error.MissingFileAction,
        } else return error.MissingFileAction;
        
        if (std.mem.eql(u8, action, "read")) {
            const path_val = obj.get("path") orelse return error.MissingPath;
            const path = switch (path_val) {
                .string => |s| s,
                else => return error.InvalidPath,
            };
            const content = try file_cmd.readFile(allocator, path);
            defer allocator.free(content);
            std.debug.print("{s}\n", .{content});
        } else if (std.mem.eql(u8, action, "write")) {
            const path_val = obj.get("path") orelse return error.MissingPath;
            const path = switch (path_val) {
                .string => |s| s,
                else => return error.InvalidPath,
            };
            const content_val = obj.get("content") orelse obj.get("text") orelse return error.MissingContent;
            const content = switch (content_val) {
                .string => |s| s,
                else => return error.InvalidContent,
            };
            try file_cmd.writeFile(path, content);
        } else if (std.mem.eql(u8, action, "append")) {
            const path_val = obj.get("path") orelse return error.MissingPath;
            const path = switch (path_val) {
                .string => |s| s,
                else => return error.InvalidPath,
            };
            const content_val = obj.get("content") orelse obj.get("text") orelse return error.MissingContent;
            const content = switch (content_val) {
                .string => |s| s,
                else => return error.InvalidContent,
            };
            try file_cmd.appendFile(path, content);
        } else if (std.mem.eql(u8, action, "exists")) {
            const path_val = obj.get("path") orelse return error.MissingPath;
            const path = switch (path_val) {
                .string => |s| s,
                else => return error.InvalidPath,
            };
            const file_exists = file_cmd.exists(path);
            std.debug.print("Exists: {}\n", .{file_exists});
        } else if (std.mem.eql(u8, action, "delete")) {
            const path_val = obj.get("path") orelse return error.MissingPath;
            const path = switch (path_val) {
                .string => |s| s,
                else => return error.InvalidPath,
            };
            try file_cmd.deleteFile(path);
        } else if (std.mem.eql(u8, action, "size")) {
            const path_val = obj.get("path") orelse return error.MissingPath;
            const path = switch (path_val) {
                .string => |s| s,
                else => return error.InvalidPath,
            };
            const size = try file_cmd.getSize(path);
            std.debug.print("Size: {d} bytes\n", .{size});
        } else if (std.mem.eql(u8, action, "list")) {
            const path_val = obj.get("path") orelse obj.get("directory") orelse return error.MissingPath;
            const path = switch (path_val) {
                .string => |s| s,
                else => return error.InvalidPath,
            };
            try file_cmd.listDir(allocator, path);
        } else if (std.mem.eql(u8, action, "mkdir")) {
            const path_val = obj.get("path") orelse return error.MissingPath;
            const path = switch (path_val) {
                .string => |s| s,
                else => return error.InvalidPath,
            };
            try file_cmd.makeDir(path);
        } else if (std.mem.eql(u8, action, "copy")) {
            const src_val = obj.get("source") orelse obj.get("src") orelse return error.MissingSource;
            const source = switch (src_val) {
                .string => |s| s,
                else => return error.InvalidSource,
            };
            const dest_val = obj.get("destination") orelse obj.get("dest") orelse return error.MissingDestination;
            const destination = switch (dest_val) {
                .string => |s| s,
                else => return error.InvalidDestination,
            };
            try file_cmd.copyFile(source, destination);
        } else if (std.mem.eql(u8, action, "move")) {
            const src_val = obj.get("source") orelse obj.get("src") orelse return error.MissingSource;
            const source = switch (src_val) {
                .string => |s| s,
                else => return error.InvalidSource,
            };
            const dest_val = obj.get("destination") orelse obj.get("dest") orelse return error.MissingDestination;
            const destination = switch (dest_val) {
                .string => |s| s,
                else => return error.InvalidDestination,
            };
            try file_cmd.moveFile(source, destination);
        }
    } else if (std.mem.eql(u8, cmd, "system") or std.mem.eql(u8, cmd, "sys")) {
        const action = if (obj.get("action")) |a| switch (a) {
            .string => |s| s,
            else => return error.MissingSystemAction,
        } else return error.MissingSystemAction;
        
        if (std.mem.eql(u8, action, "screen")) {
            const size = try system_cmd.getScreenSize();
            std.debug.print("Screen: {d}x{d}\n", .{ size.width, size.height });
        } else if (std.mem.eql(u8, action, "active")) {
            const title = try system_cmd.getActiveWindowTitle(allocator);
            defer allocator.free(title);
            std.debug.print("Active window: {s}\n", .{title});
        } else if (std.mem.eql(u8, action, "pixel")) {
            const x = jsonGetInt(obj.get("x") orelse return error.MissingCoordinate) orelse return error.InvalidCoordinate;
            const y = jsonGetInt(obj.get("y") orelse return error.MissingCoordinate) orelse return error.InvalidCoordinate;
            const color = try system_cmd.getPixelColor(x, y);
            std.debug.print("Pixel at ({d},{d}): #{X:0>6}\n", .{ x, y, color });
        } else if (std.mem.eql(u8, action, "wait")) {
            const ms = jsonGetInt(obj.get("ms") orelse obj.get("milliseconds") orelse return error.MissingDuration) orelse return error.InvalidDuration;
            system_cmd.wait(@intCast(ms));
        } else if (std.mem.eql(u8, action, "time")) {
            const time_info = try system_cmd.getSystemTime();
            std.debug.print("Time: {d}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}\n", .{ time_info.year, time_info.month, time_info.day, time_info.hour, time_info.minute, time_info.second });
        } else if (std.mem.eql(u8, action, "process") or std.mem.eql(u8, action, "running")) {
            const name_val = obj.get("name") orelse obj.get("process") orelse return error.MissingProcessName;
            const name = switch (name_val) {
                .string => |s| s,
                else => return error.InvalidProcessName,
            };
            const running = try system_cmd.isProcessRunning(allocator, name);
            std.debug.print("Process '{s}' running: {}\n", .{ name, running });
        } else if (std.mem.eql(u8, action, "env")) {
            const var_val = obj.get("variable") orelse obj.get("var") orelse obj.get("name") orelse return error.MissingVariable;
            const variable = switch (var_val) {
                .string => |s| s,
                else => return error.InvalidVariable,
            };
            const value = try system_cmd.getEnvVar(allocator, variable);
            defer allocator.free(value);
            std.debug.print("{s}={s}\n", .{ variable, value });
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
            } else if (std.mem.eql(u8, cmd, "text") or std.mem.eql(u8, cmd, "type")) {
                cli.printTextHelp();
            } else if (std.mem.eql(u8, cmd, "clipboard") or std.mem.eql(u8, cmd, "clip")) {
                cli.printClipboardHelp();
            } else if (std.mem.eql(u8, cmd, "file")) {
                cli.printFileHelp();
            } else if (std.mem.eql(u8, cmd, "system") or std.mem.eql(u8, cmd, "sys")) {
                cli.printSystemHelp();
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
        } else if (std.mem.eql(u8, action, "minimize")) {
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
                std.debug.print("Error: 'minimize' requires --title argument\n", .{});
                return;
            };
            window_cmd.minimizeWindow(allocator, t) catch |err| {
                std.debug.print("Error: failed to minimize window: {any}\n", .{err});
                return;
            };
        } else if (std.mem.eql(u8, action, "maximize")) {
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
                std.debug.print("Error: 'maximize' requires --title argument\n", .{});
                return;
            };
            window_cmd.maximizeWindow(allocator, t) catch |err| {
                std.debug.print("Error: failed to maximize window: {any}\n", .{err});
                return;
            };
        } else if (std.mem.eql(u8, action, "restore")) {
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
                std.debug.print("Error: 'restore' requires --title argument\n", .{});
                return;
            };
            window_cmd.restoreWindow(allocator, t) catch |err| {
                std.debug.print("Error: failed to restore window: {any}\n", .{err});
                return;
            };
        } else if (std.mem.eql(u8, action, "active")) {
            window_cmd.getActiveWindow(allocator) catch |err| {
                std.debug.print("Error: failed to get active window: {any}\n", .{err});
                return;
            };
        } else {
            try cli.printActionError(allocator, "window", action, &WINDOW_ACTIONS);
        }
    } else if (std.mem.eql(u8, group, "text") or std.mem.eql(u8, group, "type")) {
        if (args.len < 2) {
            std.debug.print("Error: 'text' requires text to type\n", .{});
            std.debug.print("Usage: windotool text <text-to-type>\n", .{});
            return;
        }
        const text = try std.mem.join(allocator, " ", args[1..]);
        defer allocator.free(text);
        text_cmd.typeText(text) catch |err| {
            std.debug.print("Error: failed to type text: {any}\n", .{err});
            return;
        };
    } else if (std.mem.eql(u8, group, "clipboard") or std.mem.eql(u8, group, "clip")) {
        if (args.len < 2) {
            std.debug.print("Usage: windotool clipboard <get|set|clear>\n", .{});
            return;
        }
        const action = args[1];
        if (std.mem.eql(u8, action, "get")) {
            const text = clipboard_cmd.getText(allocator) catch |err| {
                std.debug.print("Error: failed to get clipboard: {any}\n", .{err});
                return;
            };
            defer allocator.free(text);
            std.debug.print("{s}\n", .{text});
        } else if (std.mem.eql(u8, action, "set")) {
            if (args.len < 3) {
                std.debug.print("Error: 'set' requires text argument\n", .{});
                return;
            }
            const text = try std.mem.join(allocator, " ", args[2..]);
            defer allocator.free(text);
            clipboard_cmd.setText(allocator, text) catch |err| {
                std.debug.print("Error: failed to set clipboard: {any}\n", .{err});
                return;
            };
            std.debug.print("Clipboard set\n", .{});
        } else if (std.mem.eql(u8, action, "clear")) {
            clipboard_cmd.clear() catch |err| {
                std.debug.print("Error: failed to clear clipboard: {any}\n", .{err});
                return;
            };
            std.debug.print("Clipboard cleared\n", .{});
        } else {
            try cli.printActionError(allocator, "clipboard", action, &CLIPBOARD_ACTIONS);
        }
    } else if (std.mem.eql(u8, group, "file")) {
        if (args.len < 2) {
            std.debug.print("Usage: windotool file <action> [args]\n", .{});
            return;
        }
        const action = args[1];
        if (std.mem.eql(u8, action, "read")) {
            if (args.len < 3) {
                std.debug.print("Usage: windotool file read <path>\n", .{});
                return;
            }
            const content = file_cmd.readFile(allocator, args[2]) catch |err| {
                std.debug.print("Error: {any}\n", .{err});
                return;
            };
            defer allocator.free(content);
            std.debug.print("{s}", .{content});
        } else if (std.mem.eql(u8, action, "write")) {
            if (args.len < 4) {
                std.debug.print("Usage: windotool file write <path> <content>\n", .{});
                return;
            }
            const content = try std.mem.join(allocator, " ", args[3..]);
            defer allocator.free(content);
            file_cmd.writeFile(args[2], content) catch |err| {
                std.debug.print("Error: {any}\n", .{err});
                return;
            };
            std.debug.print("File written: {s}\n", .{args[2]});
        } else if (std.mem.eql(u8, action, "exists")) {
            if (args.len < 3) {
                std.debug.print("Usage: windotool file exists <path>\n", .{});
                return;
            }
            std.debug.print("{s}\n", .{if (file_cmd.exists(args[2])) "true" else "false"});
        } else if (std.mem.eql(u8, action, "list")) {
            const path = if (args.len >= 3) args[2] else ".";
            file_cmd.listDir(allocator, path) catch |err| {
                std.debug.print("Error: {any}\n", .{err});
                return;
            };
        } else {
            try cli.printActionError(allocator, "file", action, &FILE_ACTIONS);
        }
    } else if (std.mem.eql(u8, group, "system") or std.mem.eql(u8, group, "sys")) {
        if (args.len < 2) {
            std.debug.print("Usage: windotool system <screen|active|time>\n", .{});
            return;
        }
        const action = args[1];
        if (std.mem.eql(u8, action, "screen")) {
            const size = system_cmd.getScreenSize() catch |err| {
                std.debug.print("Error: {any}\n", .{err});
                return;
            };
            std.debug.print("Screen: {d}x{d}\n", .{ size.width, size.height });
        } else if (std.mem.eql(u8, action, "active")) {
            const title = system_cmd.getActiveWindowTitle(allocator) catch |err| {
                std.debug.print("Error: {any}\n", .{err});
                return;
            };
            defer allocator.free(title);
            std.debug.print("Active window: {s}\n", .{title});
        } else if (std.mem.eql(u8, action, "time")) {
            const time = system_cmd.getSystemTime() catch |err| {
                std.debug.print("Error: {any}\n", .{err});
                return;
            };
            std.debug.print("{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}\n", .{
                time.year, time.month, time.day, time.hour, time.minute, time.second,
            });
        } else {
            try cli.printActionError(allocator, "system", action, &SYSTEM_ACTIONS);
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
