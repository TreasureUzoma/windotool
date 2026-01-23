## Windotool

**windotool** - A lightweight, fast, and native Windows automation CLI written in Zig.

### Project Description

windotool is a simple yet powerful command-line tool for automating everyday tasks on Windows. Built entirely in Zig, it compiles to a single static binary with zero runtime dependencies, making it blazing-fast, portable, and easy to distribute.

Inspired by tools like AutoHotkey and pyautogui but without the bloat, windotool lets you scriptably control applications, windows, mouse, keyboard, and capture screenshots — all from the terminal or batch scripts.

Perfect for:

- Quick UI automation & macros
- Automated testing and debugging
- Streamlining repetitive workflows
- Building custom hotkeys or triggers

### Key Features

- `windotool app open "Discord"` / `close "Brave"` – Launch or close apps
- `windotool mouse move 500 300` – Precise absolute/relative mouse control
- `windotool mouse click left` – Click, double-click, right-click, scroll
- `windotool screenshot [options]` – Capture full screen, regions, windows, or clipboard (with PNG output via embedded stb_image_write)
- `windotool sleep 1000` – Delays for scripting
- Subcommand-based CLI with clean, intuitive syntax
- Extensible design — easy to add keyboard input, window management, and more

### Why Zig?

- Single standalone .exe (no installer, no DLLs)
- Direct Win32 API interop for maximum performance and control
- Memory-safe, modern systems language
- Fun to build and hack on
- I'm currently exploring the language

windotool is still early-stage. Built for speed, simplicity, and a touch of mischief.

Roadmap

This are the commands this project aims to ship at v1.

```cmd
windotool app list
windotool app open "Discord"
windotool app close "Notepad"

windotool window list
windotool window focus --title "Visual Studio Code"
windotool window move --title "Chrome" --x 0 --y 0 --w 1200 --h 800

windotool key ctrl+shift+p
windotool text "Hello world"

windotool mouse move 500 300 // done
windotool mouse click left // done
```
