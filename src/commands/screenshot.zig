const std = @import("std");
const win = @import("../utils/windows.zig");

pub const ScreenshotOptions = struct {
    filename: ?[]const u8 = null,
    to_clipboard: bool = false,
    x: i32 = 0,
    y: i32 = 0,
    width: ?i32 = null,
    height: ?i32 = null,
};

pub fn takeScreenshot(allocator: std.mem.Allocator, options: ScreenshotOptions) !void {
    const screen_w = win.GetSystemMetrics(win.SM_CXSCREEN);
    const screen_h = win.GetSystemMetrics(win.SM_CYSCREEN);

    if (screen_w <= 0 or screen_h <= 0) {
        std.debug.print("Failed to get screen dimensions.\n", .{});
        return error.ScreenshotFailed;
    }

    const capture_x = options.x;
    const capture_y = options.y;
    const capture_w = options.width orelse screen_w;
    const capture_h = options.height orelse screen_h;

    if (capture_w <= 0 or capture_h <= 0) {
        std.debug.print("Invalid screenshot dimensions: {d}x{d}\n", .{ capture_w, capture_h });
        return error.InvalidDimensions;
    }

    const hdc_screen = win.GetDC(null) orelse {
        std.debug.print("Failed to get screen DC.\n", .{});
        return error.ScreenshotFailed;
    };
    defer _ = win.ReleaseDC(null, hdc_screen);

    const hdc_mem = win.CreateCompatibleDC(hdc_screen) orelse {
        std.debug.print("Failed to create compatible DC.\n", .{});
        return error.ScreenshotFailed;
    };
    defer _ = win.DeleteDC(hdc_mem);

    const hbm = win.CreateCompatibleBitmap(hdc_screen, capture_w, capture_h) orelse {
        std.debug.print("Failed to create compatible bitmap.\n", .{});
        return error.ScreenshotFailed;
    };

    _ = win.SelectObject(hdc_mem, hbm);

    if (win.BitBlt(hdc_mem, 0, 0, capture_w, capture_h, hdc_screen, capture_x, capture_y, win.SRCCOPY) == 0) {
        _ = win.DeleteObject(hbm);
        std.debug.print("BitBlt failed.\n", .{});
        return error.ScreenshotFailed;
    }

    const should_save_file = !options.to_clipboard or options.filename != null;

    if (should_save_file) {
        var allocated_name: ?[]u8 = null;
        defer if (allocated_name) |name| allocator.free(name);

        const target_filename = if (options.filename) |name|
            name
        else blk: {
            const generated = try generateTimestampFilename(allocator, ".png");
            allocated_name = generated;
            break :blk generated;
        };

        var token: usize = 0;
        const input = win.GdiplusStartupInput{};
        if (win.GdiplusStartup(&token, &input, null) != 0) {
            if (!options.to_clipboard) _ = win.DeleteObject(hbm);
            std.debug.print("Failed to initialize GDI+.\n", .{});
            return error.GdiplusInitFailed;
        }
        defer win.GdiplusShutdown(token);

        var gdibitmap: ?*anyopaque = null;
        if (win.GdipCreateBitmapFromHBITMAP(hbm, null, &gdibitmap) != 0) {
            if (!options.to_clipboard) _ = win.DeleteObject(hbm);
            std.debug.print("Failed to create GDI+ bitmap.\n", .{});
            return error.GdiplusBitmapFailed;
        }
        defer _ = win.GdipDisposeImage(gdibitmap);

        const filename_wide = try std.unicode.utf8ToUtf16LeAllocZ(allocator, target_filename);
        defer allocator.free(filename_wide);

        const encoder = getEncoderClsid(target_filename);
        if (win.GdipSaveImageToFile(gdibitmap, filename_wide.ptr, encoder, null) != 0) {
            if (!options.to_clipboard) _ = win.DeleteObject(hbm);
            std.debug.print("Failed to save screenshot image: {s}\n", .{target_filename});
            return error.SaveImageFailed;
        }

        std.debug.print("Screenshot saved to: {s} ({d}x{d})\n", .{ target_filename, capture_w, capture_h });
    }

    if (options.to_clipboard) {
        copyToClipboard(hbm) catch |err| {
            _ = win.DeleteObject(hbm);
            std.debug.print("Failed to copy screenshot to clipboard.\n", .{});
            return err;
        };
        std.debug.print("Screenshot copied to clipboard ({d}x{d})\n", .{ capture_w, capture_h });
    } else {
        _ = win.DeleteObject(hbm);
    }
}

pub fn generateTimestampFilename(allocator: std.mem.Allocator, extension: []const u8) ![]u8 {
    var st: win.SYSTEMTIME = undefined;
    win.GetLocalTime(&st);
    return std.fmt.allocPrint(
        allocator,
        "screenshot_{d:0>4}-{d:0>2}-{d:0>2}_{d:0>2}-{d:0>2}-{d:0>2}{s}",
        .{ st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, extension },
    );
}

fn getEncoderClsid(filename: []const u8) *const win.CLSID {
    if (std.mem.endsWith(u8, filename, ".jpg") or std.mem.endsWith(u8, filename, ".jpeg")) {
        return &win.CLSID_JPEG;
    } else if (std.mem.endsWith(u8, filename, ".bmp")) {
        return &win.CLSID_BMP;
    }
    return &win.CLSID_PNG;
}

fn copyToClipboard(hbm: ?*anyopaque) !void {
    if (win.OpenClipboard(null) == 0) return error.OpenClipboardFailed;
    defer _ = win.CloseClipboard();

    if (win.EmptyClipboard() == 0) return error.EmptyClipboardFailed;
    if (win.SetClipboardData(win.CF_BITMAP, hbm) == null) return error.SetClipboardDataFailed;
}
