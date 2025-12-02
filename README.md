<div align="center">
  <img src="icon-github.png" alt="Kill Cursor" width="256">
</div>

# Kill Cursor - macOS Status Bar App

A simple macOS application that appears in the Status Bar and allows you to completely close Cursor IDE.

## Why This App Exists

This app was created to solve a problem: even after quitting Cursor IDE, it continues running in the background and consumes significant battery power. Kill Cursor allows you to completely terminate all Cursor processes with a single click, preventing unnecessary battery drain.

## Features

- **Status Bar Integration**: Appears in the macOS Status Bar
- **One-Click Kill**: Kill all Cursor processes with a single click
- **Dark/Light Mode Support**: Automatically switches icons based on macOS appearance
- **Notifications**: Shows notifications when Cursor is killed or not found
- **Keyboard Shortcuts**: 
  - `K` - Kill Cursor
  - `Q` - Quit application
- **About Menu**: View app information and credits

## Installation

1. Clone or download this repository

2. Run the build script:
```bash
chmod +x build.sh
./build.sh
```

3. Run the application:
```bash
open build/KillCursor.app
```

4. (Optional) Move the app to Applications folder:
```bash
cp -r build/KillCursor.app /Applications/
```

## Usage

- **Kill Cursor**: Click the icon in the Status Bar or select "Kill Cursor" from the menu (or press `K`)
- **About**: Select "About Kill Cursor" from the menu to view app information
- **Quit**: Select "Quit" from the menu (or press `Q`)

## Requirements

- macOS 11.0 or later
- Swift compiler

## Technical Details

- The application runs in the background (LSUIElement = true)
- Uses `killall -9 Cursor` command to terminate all Cursor processes
- Status bar icons automatically adapt to dark/light mode
- Shows a notification if Cursor is not running

## Icon Files

The app uses custom icons:
- `icon-dark.png` - Status bar icon for dark mode
- `icon-light.png` - Status bar icon for light mode
- `AppIcon.icon/Assets/skull.png` - Application icon

## License

This project is open source and available under the MIT License.

## Author

**Ahmet Bugra Avcilar**

- Website: [https://ahm.et](https://ahm.et)
- Year: 2025
