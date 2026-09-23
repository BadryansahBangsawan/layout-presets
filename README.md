<div align="center">

# Layout Presets

**Save on-screen window frames and restore them later. Missed system windows land under Missed — not a crash.**

Menu extra for macOS 14+. Lives on the **right** of the menu bar. No Dock icon.

<br/>

[![Build](https://github.com/BadryansahBangsawan/layout-presets/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/layout-presets/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/layout-presets?style=flat-square)](https://github.com/BadryansahBangsawan/layout-presets/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/layout-presets/releases/latest)

<br/>

| | |
|---|---|
| Product | `LayoutPresets` |
| Bundle ID | `engineer.badry.layoutpresets` |
| Cask | `layout-presets` |
| Status item | SF Symbol `rectangle.3.group` |
| Panel | opaque ~360×420 pt |

</div>

---

## What you get

| Piece | Behavior |
|---|---|
| **Capture** | On-screen windows via CoreGraphics + Accessibility. |
| **Restore** | Positions and sizes on windows `CGWindowList` can see (`optionOnScreenOnly` — current Space). Missing apps launch when needed. |
| **Missed** | Windows that cannot be read or moved. Expected. |
| **Project** | Optional folder on a preset. A suggestion appears when that path is frontmost. |
| **Empty** | **No presets** / **Save current as…**. |
| **Login** | Open at Login from Settings (`SMAppService`). |

---

## Download

| File | Use |
|---|---|
| **`LayoutPresets.app.zip`** | Homebrew cask / unzip, drag **LayoutPresets** onto **Applications** |

**[Releases](https://github.com/BadryansahBangsawan/layout-presets/releases/latest)**

---

## Install

### Homebrew

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew trust BadryansahBangsawan/mac-menu-apps
brew install --cask layout-presets
```

`brew trust` is required on Homebrew 6 or `brew install --cask` refuses the tap.

First open (ad-hoc signed):

```bash
xattr -cr /Applications/LayoutPresets.app
open /Applications/LayoutPresets.app
```

Still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/LayoutPresets.app` while `/Applications/LayoutPresets.app` is running (same bundle ID).

---

## How to open

This is an `LSUIElement` extra. Proof it is running is the **rectangle.3.group** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is opaque ~360×420 pt, not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

---

## Usage

1. **Save current as…** names a preset (and optional project folder). Disabled until Accessibility is trusted.
2. Restore a preset from the list. Windows that cannot be read or moved show under **Missed**.
3. A suggested preset appears when the frontmost document sits under a saved project path.
4. **Settings** at the bottom: Accessibility status, Open at Login, Quit.

---

## Permissions

**Accessibility** is required to read and set window frames. Untrusted: **Accessibility is required to capture and restore window frames.** plus **Enable Accessibility** and **Relaunch**.

Ad-hoc `codesign -s -` binds Accessibility to a **cdhash**. Reinstall is a new identity.

1. Privacy & Security → Accessibility: toggle **off**, then **on** for Layout Presets.
2. Click **Relaunch**. macOS does not grant that right to a process that is already running.

---

## Data

| What | Where |
|---|---|
| Presets | `~/Library/Application Support/Layout Presets/presets.json` |
| Last restored | UserDefaults `engineer.badry.layoutpresets.lastRestoredId` |
| Open at Login | `SMAppService.mainApp` (Settings toggle) |

Decode failure → empty list plus a red banner. The extra does not crash.

---

## Privacy

No network. Frames and bundle IDs stay on this Mac.

---

## Uninstall

```bash
brew uninstall --cask layout-presets
```

Or delete `/Applications/LayoutPresets.app`. Then:

```bash
rm -rf "$HOME/Library/Application Support/Layout Presets"
```

Turn off **Layout Presets** in System Settings → General → Login Items if it remains.

---

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **rectangle.3.group** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x LayoutPresets` then `open /Applications/LayoutPresets.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/LayoutPresets.app`. `spctl --assess` is `rejected` even when it runs. |
| `brew install --cask` refuses the tap | `brew trust BadryansahBangsawan/mac-menu-apps` |
| **Accessibility is required to capture and restore window frames.** | Toggle off/on, then **Relaunch** (cdhash). |
| Save disabled | Accessibility not trusted for this binary. |
| **Missed** rows | Windows that cannot be read or moved. Intended. |
| ~10px empty strip under the bar | Reinstall from this repo. |

---

## Build from source

```bash
git clone https://github.com/BadryansahBangsawan/layout-presets.git
cd layout-presets
swift build -c release --product LayoutPresets
bash package-app.sh
open dist/LayoutPresets.app
```

Tag `v*` runs CI: `LayoutPresets.app.zip`. Never commit `dist/`.

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. `FunTheme.swift` is copied verbatim (no shared package).

---

## FAQ

**Why is there no Dock icon?**  
It is a menu extra. Click the rectangle.3.group item on the **right** of the menu bar.

**Why is Accessibility already on, but Save is disabled?**  
Ad-hoc signing binds TCC to a **cdhash**. Toggle **off then on**, then **Relaunch**.

**Where are presets stored?**  
`~/Library/Application Support/Layout Presets/presets.json`.

**How do I stop it opening at login?**  
Settings in the panel, or System Settings → General → Login Items → **Layout Presets**.

---

<div align="center">

[MIT](LICENSE)

</div>
