const std = @import("std");

// Windows API Declarations

//  Kernel32

pub const SYSTEMTIME = extern struct {
    wYear: u16,
    wMonth: u16,
    wDayOfWeek: u16,
    wDay: u16,
    wHour: u16,
    wMinute: u16,
    wSecond: u16,
    wMilliseconds: u16,
};

pub extern "kernel32" fn Sleep(dwMilliseconds: u32) callconv(.winapi) void;
pub extern "kernel32" fn GetLocalTime(lpSystemTime: *SYSTEMTIME) callconv(.winapi) void;

//  Shell32 ─

pub extern "shell32" fn ShellExecuteW(
    hwnd: ?*anyopaque,
    lpOperation: ?[*:0]const u16,
    lpFile: [*:0]const u16,
    lpParameters: ?[*:0]const u16,
    lpDirectory: ?[*:0]const u16,
    nShowCmd: i32,
) callconv(.winapi) isize;

//  User32 ──

pub const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

pub const POINT = extern struct {
    x: i32,
    y: i32,
};

pub extern "user32" fn EnumWindows(
    callback: *const fn (?*anyopaque, isize) callconv(.winapi) i32,
    lparam: isize,
) callconv(.winapi) i32;

pub extern "user32" fn IsWindowVisible(hwnd: ?*anyopaque) callconv(.winapi) i32;
pub extern "user32" fn IsIconic(hwnd: ?*anyopaque) callconv(.winapi) i32;
pub extern "user32" fn IsZoomed(hwnd: ?*anyopaque) callconv(.winapi) i32;
pub extern "user32" fn ShowWindow(hwnd: ?*anyopaque, nCmdShow: i32) callconv(.winapi) i32;
pub extern "user32" fn BringWindowToTop(hwnd: ?*anyopaque) callconv(.winapi) i32;
pub extern "user32" fn SetForegroundWindow(hwnd: ?*anyopaque) callconv(.winapi) i32;
pub extern "user32" fn MoveWindow(
    hwnd: ?*anyopaque,
    x: i32,
    y: i32,
    nWidth: i32,
    nHeight: i32,
    bRepaint: i32,
) callconv(.winapi) i32;
pub extern "user32" fn GetWindowRect(hwnd: ?*anyopaque, lpRect: *RECT) callconv(.winapi) i32;

pub extern "user32" fn GetWindowTextW(
    hwnd: ?*anyopaque,
    text: [*]u16,
    max_count: i32,
) callconv(.winapi) i32;

pub extern "user32" fn PostMessageW(
    hwnd: ?*anyopaque,
    msg: u32,
    wparam: usize,
    lparam: isize,
) callconv(.winapi) i32;

pub extern "user32" fn SetCursorPos(x: i32, y: i32) callconv(.winapi) i32;
pub extern "user32" fn GetCursorPos(lpPoint: *POINT) callconv(.winapi) i32;

pub extern "user32" fn mouse_event(
    dwFlags: u32,
    dx: u32,
    dy: u32,
    cButtons: u32,
    dwExtraInfo: usize,
) callconv(.winapi) void;

pub extern "user32" fn GetSystemMetrics(nIndex: i32) callconv(.winapi) i32;
pub extern "user32" fn GetDC(hwnd: ?*anyopaque) callconv(.winapi) ?*anyopaque;
pub extern "user32" fn ReleaseDC(hwnd: ?*anyopaque, hdc: ?*anyopaque) callconv(.winapi) i32;

pub extern "user32" fn OpenClipboard(hWndNewOwner: ?*anyopaque) callconv(.winapi) i32;
pub extern "user32" fn CloseClipboard() callconv(.winapi) i32;
pub extern "user32" fn EmptyClipboard() callconv(.winapi) i32;
pub extern "user32" fn SetClipboardData(uFormat: u32, hMem: ?*anyopaque) callconv(.winapi) ?*anyopaque;
pub extern "user32" fn GetClipboardData(uFormat: u32) callconv(.winapi) ?*anyopaque;
pub extern "user32" fn GetForegroundWindow() callconv(.winapi) ?*anyopaque;
pub extern "user32" fn FindWindowW(lpClassName: ?[*:0]const u16, lpWindowName: ?[*:0]const u16) callconv(.winapi) ?*anyopaque;

pub extern "user32" fn SendInput(
    cInputs: u32,
    pInputs: [*]INPUT,
    cbSize: i32,
) callconv(.winapi) u32;

// ─── Kernel32 Memory Functions ──────────────────────────────────────────

pub extern "kernel32" fn GlobalAlloc(uFlags: u32, dwBytes: usize) callconv(.winapi) ?*anyopaque;
pub extern "kernel32" fn GlobalLock(hMem: ?*anyopaque) callconv(.winapi) ?*anyopaque;
pub extern "kernel32" fn GlobalUnlock(hMem: ?*anyopaque) callconv(.winapi) i32;
pub extern "kernel32" fn GlobalFree(hMem: ?*anyopaque) callconv(.winapi) ?*anyopaque;

//  GDI32

pub extern "gdi32" fn CreateCompatibleDC(hdc: ?*anyopaque) callconv(.winapi) ?*anyopaque;
pub extern "gdi32" fn CreateCompatibleBitmap(hdc: ?*anyopaque, cx: i32, cy: i32) callconv(.winapi) ?*anyopaque;
pub extern "gdi32" fn SelectObject(hdc: ?*anyopaque, h: ?*anyopaque) callconv(.winapi) ?*anyopaque;
pub extern "gdi32" fn BitBlt(
    hdc_dest: ?*anyopaque,
    x: i32,
    y: i32,
    cx: i32,
    cy: i32,
    hdc_src: ?*anyopaque,
    x1: i32,
    y1: i32,
    rop: u32,
) callconv(.winapi) i32;
pub extern "gdi32" fn DeleteObject(ho: ?*anyopaque) callconv(.winapi) i32;
pub extern "gdi32" fn DeleteDC(hdc: ?*anyopaque) callconv(.winapi) i32;
pub extern "gdi32" fn GetPixel(hdc: ?*anyopaque, x: i32, y: i32) callconv(.winapi) u32;

//  GDI+

pub const GdiplusStartupInput = extern struct {
    GdiplusVersion: u32 = 1,
    DebugEventCallback: ?*anyopaque = null,
    SuppressBackgroundThread: i32 = 0,
    SuppressExternalCodecs: i32 = 0,
};

pub const CLSID = extern struct {
    Data1: u32,
    Data2: u16,
    Data3: u16,
    Data4: [8]u8,
};

// Image encoder CLSIDs (built into Windows GDI+)
pub const CLSID_PNG = CLSID{
    .Data1 = 0x557cf406,
    .Data2 = 0x1a04,
    .Data3 = 0x11d3,
    .Data4 = .{ 0x9a, 0x73, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e },
};
pub const CLSID_JPEG = CLSID{
    .Data1 = 0x557cf401,
    .Data2 = 0x1a04,
    .Data3 = 0x11d3,
    .Data4 = .{ 0x9a, 0x73, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e },
};
pub const CLSID_BMP = CLSID{
    .Data1 = 0x557cf400,
    .Data2 = 0x1a04,
    .Data3 = 0x11d3,
    .Data4 = .{ 0x9a, 0x73, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e },
};

pub extern "gdiplus" fn GdiplusStartup(token: *usize, input: *const GdiplusStartupInput, output: ?*anyopaque) callconv(.winapi) i32;
pub extern "gdiplus" fn GdiplusShutdown(token: usize) callconv(.winapi) void;
pub extern "gdiplus" fn GdipCreateBitmapFromHBITMAP(hbm: ?*anyopaque, hpal: ?*anyopaque, bitmap: *?*anyopaque) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipSaveImageToFile(image: ?*anyopaque, filename: [*:0]const u16, clsidEncoder: *const CLSID, encoderParams: ?*anyopaque) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipDisposeImage(image: ?*anyopaque) callconv(.winapi) i32;

//  Constants ──

pub const MOUSEEVENTF_LEFTDOWN: u32 = 0x0002;
pub const MOUSEEVENTF_LEFTUP: u32 = 0x0004;
pub const MOUSEEVENTF_RIGHTDOWN: u32 = 0x0008;
pub const MOUSEEVENTF_RIGHTUP: u32 = 0x0010;
pub const MOUSEEVENTF_MIDDLEDOWN: u32 = 0x0020;
pub const MOUSEEVENTF_MIDDLEUP: u32 = 0x0040;
pub const MOUSEEVENTF_WHEEL: u32 = 0x0800;

pub const WM_CLOSE: u32 = 0x0010;
pub const SRCCOPY: u32 = 0x00CC0020;
pub const SM_CXSCREEN: i32 = 0;
pub const SM_CYSCREEN: i32 = 1;
pub const CF_BITMAP: u32 = 2;
pub const CF_UNICODETEXT: u32 = 13;
pub const SW_RESTORE: i32 = 9;
pub const SW_SHOW: i32 = 5;
pub const SW_MINIMIZE: i32 = 6;
pub const SW_MAXIMIZE: i32 = 3;

pub const INPUT_KEYBOARD: u32 = 1;
pub const KEYEVENTF_KEYUP: u32 = 0x0002;

pub const GMEM_MOVEABLE: u32 = 0x0002;

// Virtual key codes
pub const VK_BACK: u16 = 0x08;
pub const VK_TAB: u16 = 0x09;
pub const VK_RETURN: u16 = 0x0D;
pub const VK_SHIFT: u16 = 0x10;
pub const VK_CONTROL: u16 = 0x11;
pub const VK_MENU: u16 = 0x12; // Alt
pub const VK_PAUSE: u16 = 0x13;
pub const VK_CAPITAL: u16 = 0x14; // Caps Lock
pub const VK_ESCAPE: u16 = 0x1B;
pub const VK_SPACE: u16 = 0x20;
pub const VK_PRIOR: u16 = 0x21; // Page Up
pub const VK_NEXT: u16 = 0x22; // Page Down
pub const VK_END: u16 = 0x23;
pub const VK_HOME: u16 = 0x24;
pub const VK_LEFT: u16 = 0x25;
pub const VK_UP: u16 = 0x26;
pub const VK_RIGHT: u16 = 0x27;
pub const VK_DOWN: u16 = 0x28;
pub const VK_SNAPSHOT: u16 = 0x2C; // Print Screen
pub const VK_INSERT: u16 = 0x2D;
pub const VK_DELETE: u16 = 0x2E;
pub const VK_LWIN: u16 = 0x5B;
pub const VK_RWIN: u16 = 0x5C;
pub const VK_F1: u16 = 0x70;
pub const VK_F2: u16 = 0x71;
pub const VK_F3: u16 = 0x72;
pub const VK_F4: u16 = 0x73;
pub const VK_F5: u16 = 0x74;
pub const VK_F6: u16 = 0x75;
pub const VK_F7: u16 = 0x76;
pub const VK_F8: u16 = 0x77;
pub const VK_F9: u16 = 0x78;
pub const VK_F10: u16 = 0x79;
pub const VK_F11: u16 = 0x7A;
pub const VK_F12: u16 = 0x7B;

//  Win32 Input Structs

pub const MOUSEINPUT = extern struct {
    dx: i32 = 0,
    dy: i32 = 0,
    mouseData: u32 = 0,
    dwFlags: u32 = 0,
    time: u32 = 0,
    dwExtraInfo: usize = 0,
};

pub const KEYBDINPUT = extern struct {
    wVk: u16,
    wScan: u16 = 0,
    dwFlags: u32 = 0,
    time: u32 = 0,
    dwExtraInfo: usize = 0,
};

pub const HARDWAREINPUT = extern struct {
    uMsg: u32 = 0,
    wParamL: u16 = 0,
    wParamH: u16 = 0,
};

pub const INPUT = extern struct {
    type: u32,
    u: extern union {
        mi: MOUSEINPUT,
        ki: KEYBDINPUT,
        hi: HARDWAREINPUT,
    },
};

// Process and memory management
pub const PROCESS_QUERY_INFORMATION = 0x0400;
pub const PROCESS_VM_READ = 0x0010;
pub const MAX_PATH = 260;

pub const PROCESS_MEMORY_COUNTERS = extern struct {
    cb: u32,
    PageFaultCount: u32,
    PeakWorkingSetSize: usize,
    WorkingSetSize: usize,
    QuotaPeakPagedPoolUsage: usize,
    QuotaPagedPoolUsage: usize,
    QuotaPeakNonPagedPoolUsage: usize,
    QuotaNonPagedPoolUsage: usize,
    PagefileUsage: usize,
    PeakPagefileUsage: usize,
};

pub extern "kernel32" fn OpenProcess(
    dwDesiredAccess: u32,
    bInheritHandle: u32,
    dwProcessId: u32,
) callconv(.winapi) ?*anyopaque;

pub extern "kernel32" fn CloseHandle(
    hObject: ?*anyopaque,
) callconv(.winapi) i32;

pub extern "kernel32" fn QueryFullProcessImageNameA(
    hProcess: ?*anyopaque,
    dwFlags: u32,
    lpExeName: [*]u8,
    lpdwSize: *u32,
) callconv(.winapi) i32;

pub extern "psapi" fn GetProcessMemoryInfo(
    Process: ?*anyopaque,
    ppsmemCounters: *PROCESS_MEMORY_COUNTERS,
    cb: u32,
) callconv(.winapi) i32;

// Window placement
pub const WINDOWPLACEMENT = extern struct {
    length: u32,
    flags: u32,
    showCmd: u32,
    ptMinPosition: POINT,
    ptMaxPosition: POINT,
    rcNormalPosition: RECT,
};

pub extern "user32" fn GetWindowPlacement(
    hWnd: HWND,
    lpwndpl: *WINDOWPLACEMENT,
) callconv(.winapi) i32;

pub extern "user32" fn IsWindowEnabled(
    hWnd: HWND,
) callconv(.winapi) i32;

pub extern "user32" fn GetClassNameA(
    hWnd: HWND,
    lpClassName: [*]u8,
    nMaxCount: i32,
) callconv(.winapi) i32;

pub extern "user32" fn GetWindowThreadProcessId(
    hWnd: HWND,
    lpdwProcessId: *u32,
) callconv(.winapi) u32;

// GDI for pixel capture
pub extern "gdi32" fn CreateCompatibleDC(
    hdc: ?HDC,
) callconv(.winapi) ?HDC;

pub extern "gdi32" fn DeleteDC(
    hdc: ?HDC,
) callconv(.winapi) i32;

pub extern "gdi32" fn CreateCompatibleBitmap(
    hdc: ?HDC,
    cx: i32,
    cy: i32,
) callconv(.winapi) ?*anyopaque;

pub extern "gdi32" fn DeleteObject(
    ho: ?*anyopaque,
) callconv(.winapi) i32;

pub extern "gdi32" fn SelectObject(
    hdc: ?HDC,
    h: ?*anyopaque,
) callconv(.winapi) ?*anyopaque;

pub extern "gdi32" fn BitBlt(
    hdc: ?HDC,
    x: i32,
    y: i32,
    cx: i32,
    cy: i32,
    hdcSrc: ?HDC,
    x1: i32,
    y1: i32,
    rop: u32,
) callconv(.winapi) i32;

pub const SRCCOPY: u32 = 0x00CC0020;

pub const BITMAPINFOHEADER = extern struct {
    biSize: u32,
    biWidth: i32,
    biHeight: i32,
    biPlanes: u16,
    biBitCount: u16,
    biCompression: u32,
    biSizeImage: u32,
    biXPelsPerMeter: i32,
    biYPelsPerMeter: i32,
    biClrUsed: u32,
    biClrImportant: u32,
};

pub const RGBQUAD = extern struct {
    rgbBlue: u8,
    rgbGreen: u8,
    rgbRed: u8,
    rgbReserved: u8,
};

pub const BITMAPINFO = extern struct {
    bmiHeader: BITMAPINFOHEADER,
    bmiColors: [1]RGBQUAD,
};

pub const BI_RGB: u32 = 0;
pub const DIB_RGB_COLORS: u32 = 0;

pub extern "gdi32" fn GetDIBits(
    hdc: ?HDC,
    hbm: ?*anyopaque,
    start: u32,
    cLines: u32,
    lpvBits: ?*anyopaque,
    lpbmi: *BITMAPINFO,
    usage: u32,
) callconv(.winapi) i32;
