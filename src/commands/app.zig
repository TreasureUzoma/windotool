const std = @import("std");
const win = @import("../utils/windows.zig");

pub fn closeApp(allocator: std.mem.Allocator, name: []const u8) !void {
    const exe_name = if (std.mem.endsWith(u8, name, ".exe"))
        name
    else
        try std.mem.concat(allocator, u8, &.{ name, ".exe" });
    defer if (!std.mem.endsWith(u8, name, ".exe")) allocator.free(exe_name);

    var child = std.process.Child.init(
        &.{ "taskkill", "/IM", exe_name },
        allocator,
    );

    try child.spawn();
    const result = try child.wait();

    switch (result) {
        .Exited => |code| {
            if (code != 0) {
                std.debug.print("Failed to close application: {s}\n", .{exe_name});
                std.debug.print("Check if it is running and if the name is correct.\n", .{});
            }
        },
        else => {
            std.debug.print("Failed to close application: {s}\n", .{exe_name});
        },
    }
}

pub fn openApp(allocator: std.mem.Allocator, app: []const u8) !void {
    const app_wide = try std.unicode.utf8ToUtf16LeAllocZ(allocator, app);
    defer allocator.free(app_wide);

    const operation = std.unicode.utf8ToUtf16LeAllocZ(allocator, "open") catch return error.OutOfMemory;
    defer allocator.free(operation);

    const result = win.ShellExecuteW(
        null,
        operation,
        app_wide,
        null,
        null,
        1,
    );

    if (result <= 32) {
        std.debug.print("Failed to open: {s}\n", .{app});
        std.debug.print("Check if it exists and if the path is correct.\n", .{});
    }
}

pub fn listInstalledApps(allocator: std.mem.Allocator) !void {
    const script =
        "$ErrorActionPreference = 'SilentlyContinue'; " ++
        "$apps = @(); " ++
        "$keys = @(" ++
        "'HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*'," ++
        "'HKLM:\\Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*'," ++
        "'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*'" ++
        "); " ++
        "$apps += Get-ItemProperty $keys | ForEach-Object { $_.DisplayName }; " ++
        "$apps += Get-StartApps | ForEach-Object { $_.Name }; " ++
        "$folders = @(" ++
        "[Environment]::GetFolderPath('StartMenu') + '\\Programs'," ++
        "[Environment]::GetFolderPath('CommonStartMenu') + '\\Programs'" ++
        "); " ++
        "foreach ($folder in $folders) { " ++
        "if (Test-Path $folder) { " ++
        "$apps += Get-ChildItem $folder -Filter '*.lnk' -Recurse -File | ForEach-Object { $_.BaseName } " ++
        "} }; " ++
        "$apps | Where-Object { $_ -and $_.Trim() } | Sort-Object -Unique";

    var child = std.process.Child.init(
        &.{ "powershell.exe", "-NoProfile", "-Command", script },
        allocator,
    );

    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    try child.spawn();

    const result = try child.wait();

    switch (result) {
        .Exited => |code| {
            if (code != 0) return error.FailedToListInstalledApps;
        },
        else => return error.FailedToListInstalledApps,
    }
}

pub fn listRunningApps(allocator: std.mem.Allocator) !void {
    var child = std.process.Child.init(
        &.{
            "tasklist.exe",
            "/FO",
            "TABLE",
        },
        allocator,
    );

    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    try child.spawn();
    const result = try child.wait();

    switch (result) {
        .Exited => |code| {
            if (code != 0) return error.FailedToListRunningApps;
        },
        else => return error.FailedToListRunningApps,
    }
}
