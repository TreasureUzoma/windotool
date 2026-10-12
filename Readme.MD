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
- Minimize, maximize, and restore windows.
- Get active window title.
- Get detailed window information (size, position, state).
- Scroll window content.

**Mouse automation**

- Move the cursor using screen coordinates.
- Click left and right mouse buttons.
- Support additional mouse actions such as double-clicking and scrolling.
- Get current mouse position.

**Keyboard and text input**

- Simulate keyboard shortcuts and key combinations.
- Type text character-by-character into the active application.
- Proper handling of uppercase, lowercase, and special characters.

**Clipboard operations**

- Get current clipboard text content.
- Set clipboard to specified text.
- Clear clipboard content.
- Full Unicode support.

**File operations**

- Read and write files.
- Append content to existing files.
- Check file/directory existence.
- Delete files and directories.
- Get file size.
- List directory contents.
- Create directories.
- Copy and move files.

**System information**

- Get screen resolution.
- Get active window title.
- Read pixel color at coordinates.
- Check if processes are running.
- Get environment variables.
- Get current system time.
- Wait/sleep for specified duration.

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
│   ├── screenshot.zig      # Screenshot capture
│   ├── text.zig            # Text typing
│   ├── clipboard.zig       # Clipboard operations
│   ├── file.zig            # File operations
│   └── system.zig          # System information
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
windotool window minimize --title "Chrome"
windotool window maximize --title "Notepad"
windotool window restore --title "Chrome"
windotool window active

# Mouse control
windotool mouse move 500 300
windotool mouse click left
windotool mouse click double
windotool mouse scroll 120
windotool mouse pos

# Keyboard automation
windotool key ctrl+shift+p
windotool key alt+f4
windotool key win+r

# Text typing
windotool text type "Hello, World!"
windotool text type "user@example.com"

# Clipboard operations
windotool clipboard get
windotool clipboard set "Hello from windotool"
windotool clipboard clear
# Short aliases also work
windotool clip get
windotool clip set "Quick copy"

# File operations
windotool file read "C:\data.txt"
windotool file write "C:\output.txt" "Hello, World!"
windotool file append "C:\log.txt" "New log entry"
windotool file exists "C:\temp"
windotool file delete "C:\old.txt"
windotool file size "C:\document.pdf"
windotool file list "C:\Users"
windotool file mkdir "C:\new_folder"
windotool file copy "C:\source.txt" "C:\backup.txt"
windotool file move "C:\old_name.txt" "C:\new_name.txt"

# System information
windotool system screen
windotool system active
windotool system pixel 100 200
windotool system wait 1000
windotool system time
windotool system process "chrome.exe"
windotool system env "PATH"
# Short aliases also work
windotool sys screen
windotool sys time

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

**Example: AI Agent Workflow with New Features**

```json
{
  "actions": [
    {
      "command": "system",
      "action": "screen",
      "comment": "Get screen dimensions"
    },
    {
      "command": "system",
      "action": "active",
      "comment": "Check active window"
    },
    {
      "command": "clipboard",
      "action": "set",
      "text": "https://example.com",
      "comment": "Copy URL to clipboard"
    },
    {
      "command": "app",
      "action": "open",
      "name": "notepad"
    },
    {
      "command": "sleep",
      "ms": 1000
    },
    {
      "command": "window",
      "action": "maximize",
      "title": "Notepad"
    },
    {
      "command": "text",
      "action": "type",
      "text": "Hello from AI agent!"
    },
    {
      "command": "sleep",
      "ms": 500
    },
    {
      "command": "key",
      "combo": "enter"
    },
    {
      "command": "key",
      "combo": "ctrl+v",
      "comment": "Paste URL from clipboard"
    },
    {
      "command": "file",
      "action": "write",
      "path": "C:\\temp\\log.txt",
      "content": "Automation completed successfully"
    }
  ]
}
```

**Example: File Processing Automation**

```json
{
  "actions": [
    {
      "command": "file",
      "action": "exists",
      "path": "C:\\data\\input.txt"
    },
    {
      "command": "file",
      "action": "read",
      "path": "C:\\data\\input.txt"
    },
    {
      "command": "clipboard",
      "action": "get",
      "comment": "Read clipboard content"
    },
    {
      "command": "file",
      "action": "write",
      "path": "C:\\data\\output.txt",
      "content": "Processed data"
    },
    {
      "command": "file",
      "action": "copy",
      "source": "C:\\data\\output.txt",
      "destination": "C:\\backup\\output.txt"
    },
    {
      "command": "system",
      "action": "time",
      "comment": "Log completion time"
    }
  ]
}
```

**Example: System Monitoring**

```json
{
  "actions": [
    {
      "command": "system",
      "action": "process",
      "name": "chrome.exe",
      "comment": "Check if Chrome is running"
    },
    {
      "command": "system",
      "action": "pixel",
      "x": 100,
      "y": 200,
      "comment": "Sample pixel color"
    },
    {
      "command": "window",
      "action": "active",
      "comment": "Get active window title"
    },
    {
      "command": "file",
      "action": "append",
      "path": "C:\\logs\\monitor.log",
      "content": "System check completed\n"
    }
  ]
}
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
- **AI-ready:** Comprehensive command set designed for AI agents to control Windows PCs programmatically.

**Binary Sizes:**

- Debug build: ~1.35 MB (includes debug symbols)
- Release (optimized): ~343 KB (single executable, no dependencies)

### AI Agent Integration

Windotool is designed as a comprehensive control interface for AI agents operating on Windows systems. With its JSON batch execution and extensive command set, AI agents can:

**Complete System Control:**

- Read and write files for data persistence
- Monitor system state (processes, screen resolution, active windows)
- Read pixel colors for visual verification
- Check clipboard content and manipulate text

**Application Automation:**

- Launch and manage applications
- Control window positions and states
- Type text and simulate keyboard shortcuts
- Perform mouse actions with precise coordinates

**Workflow Orchestration:**

- Chain multiple commands in JSON batches
- Add delays and synchronization points
- Handle errors gracefully with clear feedback
- Execute complex multi-step automations

**Example AI Agent Use Cases:**

- Browser automation for web scraping and testing
- Document processing and data entry
- System monitoring and health checks
- Automated software testing and quality assurance
- File organization and batch processing
- Screen capture and visual verification
- Clipboard-based data transfer workflows

The combination of file operations, system information commands, window management, and input simulation provides AI agents with everything needed for comprehensive Windows automation.

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
│   ├── screenshot.zig      # Screenshot capture
│   ├── text.zig            # Text typing
│   ├── clipboard.zig       # Clipboard operations
│   ├── file.zig            # File operations
│   └── system.zig          # System information
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

Windotool provides comprehensive Windows automation capabilities designed for both human users and AI agents. With support for window management, input simulation, file operations, clipboard manipulation, system information retrieval, and JSON batch execution, it offers a complete control interface for automating Windows tasks. The project demonstrates practical systems programming with Zig while delivering a lightweight, native, and extensible automation tool.

### License

See [LICENSE](LICENSE) for details.
