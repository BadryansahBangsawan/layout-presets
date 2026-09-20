<div align="center">

# Layout Presets

**Save and restore macOS window arrangements with one click.**  
macOS menu extra — lives in the menu bar, no Dock icon.

<br/>

[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/layout-presets?style=flat-square&color=76B900&label=latest)](https://github.com/BadryansahBangsawan/layout-presets/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/layout-presets/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)

<br/>

</div>

---

## Download

| Platform | File |
|---|---|
| **macOS** (Apple Silicon & Intel, macOS 14+) | `LayoutPresets-*-macos.zip` |

[Go to Releases](https://github.com/BadryansahBangsawan/layout-presets/releases/latest)

---

## Installation

### Homebrew (recommended)

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew install --cask layout-presets
```

A **Layout Presets** icon appears in the menu bar. If Gatekeeper blocks it on first launch:

```bash
xattr -cr /Applications/LayoutPresets.app && open /Applications/LayoutPresets.app
```

Or: right-click the app, Open, then Open again. Still blocked? **System Settings → Privacy & Security → Open Anyway**.

### GitHub Releases

1. Download `LayoutPresets-*-macos.zip` from [Releases](https://github.com/BadryansahBangsawan/layout-presets/releases/latest)
2. Unzip and drag **LayoutPresets** into Applications
3. On first launch, run the xattr command above if Gatekeeper blocks it

### Build from source

```bash
git clone https://github.com/BadryansahBangsawan/layout-presets.git
cd layout-presets
bash package-app.sh
open dist/LayoutPresets.app
```

Requires Xcode Command Line Tools and Swift 5.9+.

---

## Notes

– Requires Accessibility permission to read and set window frames.
– Presets are stored in ~/Library/Application Support/LayoutPresets/.
– Works best in non-fullscreen windows; fullscreen spaces are skipped.
– Restore applies frames on the current Space only — switch to the Space that holds the windows before restoring, or Mission Control will leave them on the other Space.
– No Dock icon; lives entirely in the menu bar.
– On multi-display setups, save a preset while the target arrangement is visible on each screen — restore reapplies frames per display ID when that display is connected.
– If Accessibility was denied once, open System Settings → Privacy & Security → Accessibility, toggle Layout Presets off/on, then quit and reopen the menu extra so AX permissions reload.
– Optional Open at Login is in the in-app Settings panel (ServiceManagement); toggle it there rather than adding a Login Item by hand.
– Suggested presets appear when an optional project folder is attached — useful for jumping back to a layout tied to the folder you just opened.

---

<div align="center">

Made with ♥ for developers who prefer staying in the flow.

</div>
