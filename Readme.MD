# Windotool

**Windotool** is a lightweight, native Windows automation CLI written in Zig.

## Overview

Windotool makes Windows automation accessible from the terminal. It provides a simple command-line interface for controlling applications, managing windows, automating mouse and keyboard input, capturing screenshots, and running scripted workflows.

Inspired by tools like AutoHotkey and PyAutoGUI, Windotool focuses on simplicity, speed, and native Windows integration.

## Setup

### Prerequisites

- [Zig 0.15.2 preferably or later](https://ziglang.org/download/)
- Windows 10 or later

### Building from Source

1. Clone the repository:

```cmd
git clone <repository-url>
cd windotool
```

2. Build the project:

```cmd
zig build
```

3. The executable will be available at `zig-out\bin\windotool.exe`

### Installation Options

**Option 1: Run from project directory (easiest)**

```cmd
.\zig-out\bin\windotool.exe --help
```

**Option 2: Use the setup script (recommended)**

```cmd
.\setup.ps1
```

This interactive script will guide you through adding windotool to your PATH.

**Option 3: Add to PATH manually**

Add the full path to `zig-out\bin` to your system PATH:

1. Press Win + X, select 'System'
2. Click 'Advanced system settings' → 'Environment Variables'
3. Under 'User variables', select 'Path' and click 'Edit'
4. Click 'New' and add: `C:\path\to\windotool\zig-out\bin`
5. Click OK and restart your terminal

**Option 4: Copy to Windows directory**

```cmd
# Requires administrator privileges
copy zig-out\bin\windotool.exe C:\Windows\
```

After setup, you can use `windotool` from anywhere!

### Quick Start

Test the installation:

```cmd
# Show help
.\zig-out\bin\windotool.exe --help

# Check version
.\zig-out\bin\windotool.exe --version

# Try a simple command
.\zig-out\bin\windotool.exe mouse pos
```

### Features

**Application management**

- List installed applications and running processes.
- Launch applications by name or executable path.
- Close running applications.

**Window management**

- List open windows.
- Focus windows by title.
- Move and resize windows.
- Get detailed window information (size, position, state).
- Scroll window content.

**Mouse automation**

- Move the cursor using screen coordinates.
- Click left and right mouse buttons.
- Support additional mouse actions such as double-clicking and scrolling.

**Keyboard and text input**

- Simulate keyboard shortcuts and key combinations.
- Type text into the active application.

**Screenshots**

- Capture the screen, selected regions, or individual windows.
- Support screenshot output options, including PNG.

**Scripting and automation**

- Add delays between actions.
- Execute sequences of automation instructions from JSON batch files.
- Combine commands into repeatable workflows.

**Robust error handling**

- Clear error messages with context
- Intelligent command suggestions for typos
- Graceful handling of invalid inputs

### Project Structure

```
src/
├── main.zig                 # Entry point
├── root.zig                 # Library exports
├── utils.zig                # Command dispatcher
├── commands/
│   ├── app.zig             # Application control
│   ├── window.zig          # Window management
│   ├── mouse.zig           # Mouse control
│   ├── keyboard.zig        # Keyboard input
│   └── screenshot.zig      # Screenshot capture
└── utils/
    ├── windows.zig         # Windows API declarations
    ├── errors.zig          # Error types
    └── cli.zig             # CLI helpers (help, suggestions)
```

### Usage

```cmd
# Get help
windotool --help
windotool --version
windotool mouse --help

# Application management
windotool app list
windotool app list --running
windotool app open "Discord"
windotool app close "Notepad"

# Window management
windotool window list
windotool window focus --title "Visual Studio Code"
windotool window move --title "Chrome" --x 0 --y 0 --w 1200 --h 800
windotool window info --title "Chrome"
windotool window scroll --title "Chrome" 120

# Mouse control
windotool mouse move 500 300
windotool mouse click left
windotool mouse scroll 120
windotool mouse pos

# Keyboard automation
windotool key ctrl+shift+p
windotool key alt+f4
windotool key win+r

# Screenshots
windotool screenshot
windotool screenshot output.png
windotool screenshot -c  # Copy to clipboard
windotool screenshot -r 0 0 800 600 region.png

# Utility
windotool sleep 1000

# Batch execution
windotool batch instructions.json
```

### Error Handling Examples

Windotool provides helpful error messages with suggestions:

```cmd
$ windotool mousee
Error: unknown command "mousee"

Did you mean this?
    mouse

Run 'windotool --help' for usage.
```

```cmd
$ windotool mouse movee
Error: unknown action "movee" for "mouse"

Did you mean this?
    move

Run 'windotool mouse --help' for usage.
```

Invalid inputs are caught gracefully:

```cmd
$ windotool mouse move abc 100
Error: invalid x coordinate 'abc': error.InvalidCharacter
```

### JSON Batch Execution

You can automate complex workflows by creating JSON batch files with multiple commands.

**Example: Automated Window Interaction**

Create a file named `automation.json`:

```json
{
  "actions": [
    {
      "command": "window",
      "action": "info",
      "title": "Chrome",
      "comment": "Get information about Chrome window"
    },
    {
      "command": "sleep",
      "ms": 500
    },
    {
      "command": "window",
      "action": "focus",
      "title": "Chrome",
      "comment": "Bring Chrome to foreground"
    },
    {
      "command": "sleep",
      "ms": 300
    },
    {
      "command": "window",
      "action": "scroll",
      "title": "Chrome",
      "delta": 240,
      "comment": "Scroll down"
    },
    {
      "command": "sleep",
      "ms": 500
    },
    {
      "command": "window",
      "action": "scroll",
      "title": "Chrome",
      "delta": -240,
      "comment": "Scroll back up"
    },
    {
      "command": "mouse",
      "action": "move",
      "x": 500,
      "y": 300,
      "comment": "Move mouse to position"
    },
    {
      "command": "sleep",
      "ms": 200
    },
    {
      "command": "mouse",
      "action": "click",
      "button": "left",
      "comment": "Click left mouse button"
    },
    {
      "command": "key",
      "combo": "ctrl+a",
      "comment": "Select all"
    }
  ]
}
```

Execute the batch:

```cmd
windotool batch automation.json
```

**More Examples:**

```json
{
  "actions": [
    { "command": "app", "action": "open", "name": "notepad" },
    { "command": "sleep", "ms": 1000 },
    { "command": "window", "action": "focus", "title": "Notepad" },
    { "command": "key", "combo": "ctrl+v" },
    { "command": "sleep", "ms": 500 },
    { "command": "key", "combo": "ctrl+s" }
  ]
}
```

```json
{
  "actions": [
    { "command": "screenshot", "filename": "before.png" },
    {
      "command": "window",
      "action": "move",
      "title": "App",
      "x": 0,
      "y": 0,
      "w": 1920,
      "h": 1080
    },
    { "command": "sleep", "ms": 500 },
    { "command": "screenshot", "filename": "after.png" }
  ]
}
```

### Why Zig?

- **Native performance:** Built with Zig and direct Windows API integration.
- **Portable distribution:** Designed to compile into a standalone Windows executable without requiring a separate runtime.
- **Lightweight:** No heavyweight automation framework required. The optimized release binary is only ~343 KB.
- **Extensible:** A modular foundation for adding more Windows automation capabilities.

**Binary Sizes:**

- Debug build: ~1.35 MB (includes debug symbols)
- Release (optimized): ~343 KB (single executable, no dependencies)

## Development

### Project Structure

```
src/
├── main.zig                 # Entry point with error handling
├── root.zig                 # Library exports
├── utils.zig                # Command dispatcher & batch executor
├── commands/
│   ├── app.zig             # Application control
│   ├── window.zig          # Window management
│   ├── mouse.zig           # Mouse control
│   ├── keyboard.zig        # Keyboard simulation
│   └── screenshot.zig      # Screenshot capture
└── utils/
    ├── windows.zig         # Windows API declarations
    ├── errors.zig          # Error types
    └── cli.zig             # CLI helpers & error messages
```

### Building

```cmd
# Debug build
zig build

# Release build (optimized)
zig build -Doptimize=ReleaseFast

# Run directly
zig build run -- mouse pos

# Run tests
zig build test
```

### Contributing

Contributions are welcome! When adding new features:

1. Follow the existing modular structure
2. Add error handling with helpful messages
3. Update the CLI help text in `src/utils/cli.zig`
4. Add command to dispatcher in `src/utils.zig`
5. Update README with examples

### Extending Commands

To add a new command:

1. Create a new file in `src/commands/` (e.g., `newfeature.zig`)
2. Implement your functions using Windows APIs from `src/utils/windows.zig`
3. Add imports and command handling in `src/utils.zig`
4. Add help text in `src/utils/cli.zig`
5. Update `VALID_COMMANDS` and action arrays

Example:

```zig
// In src/commands/newfeature.zig
const std = @import("std");
const win = @import("../utils/windows.zig");

pub fn doSomething(param: []const u8) !void {
    // Your implementation
}
```

### Project Status

Windotool brings its core Windows automation commands together in one lightweight CLI. The project is also an opportunity to explore Zig, systems programming, and native Windows APIs through a practical, evolving tool.

### License

See [LICENSE](LICENSE) for details.
