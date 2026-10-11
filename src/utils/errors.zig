// Common error types for windotool

pub const WindowError = error{
    WindowNotFound,
    GetWindowRectFailed,
    MoveWindowFailed,
};

pub const MouseError = error{
    SetCursorPosFailed,
    GetCursorPosFailed,
};

pub const KeyboardError = error{
    TooManyKeys,
    UnknownKey,
    NoKeys,
    SendInputFailed,
};

pub const ScreenshotError = error{
    ScreenshotFailed,
    InvalidDimensions,
    GdiplusInitFailed,
    GdiplusBitmapFailed,
    SaveImageFailed,
    OpenClipboardFailed,
    EmptyClipboardFailed,
    SetClipboardDataFailed,
};

pub const AppError = error{
    FailedToListInstalledApps,
    FailedToListRunningApps,
    OutOfMemory,
};
