# Layout Presets

Save the current window layout and restore it later — frames, apps, optional project path.

Menu extra for macOS 14+. It lives in the menu bar and does not show a Dock icon.

## Features

- Capture on-screen windows (CoreGraphics + Accessibility).
- Restore positions and sizes; launch missing apps when needed.
- Windows that cannot be read or moved are listed under **Missed**, not a crash.
- Optional project path on a preset; a suggestion appears when that path is frontmost.
- Empty state: **Save the current window layout**.

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later
- Accessibility to read and set window frames

## Install

```bash
git clone https://github.com/BadryansahBangsawan/layout-presets.git
cd layout-presets
bash package-app.sh
open dist/LayoutPresets.app
```

`package-app.sh` builds a release binary, wraps `dist/LayoutPresets.app`, and ad-hoc codesigns it (`codesign -s -`). Unsigned is fine for local use.

Enable **Open at Login** from Settings if you want it after reboot.

## Usage

- **Save current as…** names a preset (and optional project folder).
- Restore a preset from the list. Do not expect every system/utility window to move; those show up under Missed.
- Suggested preset appears when the frontmost document sits under a saved project path.

## Permissions

- **Accessibility** — required. Untrusted: banner **Accessibility is required to capture and restore window frames.** plus **Enable Accessibility**.

Denied permissions must not crash the app. You should see a banner and a button to open System Settings.

## Privacy

No network. Presets are `~/Library/Application Support/Layout Presets/`.

Bundle ID: `engineer.badry.layoutpresets`.

## Development

```bash
swift build
swift build -c release --product LayoutPresets
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`.

## License

[MIT](LICENSE)
