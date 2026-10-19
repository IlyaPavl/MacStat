# MacStat

A lightweight menu bar monitor for Apple Silicon Macs: CPU load, CPU and GPU temperature, fan speed and memory use, right next to the clock.

![MacStat in the menu bar](docs/screenshots/menubar.png)

## Features

- **Live menu bar readings.** Pick the metrics you want and the order they appear in. Show each one on its own, or stack two in a single column to save space.
- **Three menu bar styles:** two rows, icons and values, or icon only. Compact and standard density.
- **Popover with history.** Click the menu bar item to see every metric in a glass card with a short chart of recent values.
- **Copy summary.** Copy all current readings as plain text in one click.
- **Launch at login**, with an update interval of 1, 2 or 5 seconds.
- **Localized** in English, Russian, French, Spanish, Arabic and Traditional Chinese. You can switch the app language in Settings without changing the system language.
- **Native and private.** Built with SwiftUI and Swift Charts, with no third-party dependencies, no network access and no analytics.

<p align="center">
  <img src="docs/screenshots/popover.png" alt="Popover with metric cards" width="380">
  <img src="docs/screenshots/settings.png" alt="Settings window" width="420">
</p>

## Requirements

- macOS 27 or later
- A Mac with Apple Silicon

## Installation

1. Download the latest `MacStat-<version>.dmg` from [Releases](../../releases).
2. Open the disk image and drag **MacStat** to **Applications**.
3. Open MacStat. The app is not notarized, so on first launch macOS will block it. Open **System Settings → Privacy & Security** and click **Open Anyway** next to the MacStat message.

MacStat has no Dock icon. It lives in the menu bar only; quit it from the popover.

## Building from source

You need Xcode 27 or later.

```bash
git clone https://github.com/IlyaPavl/MacStat.git
cd MacStat
open MacStat.xcodeproj
```

To build an ad-hoc signed disk image in `build/`:

```bash
./make_dmg.sh
```

To run the unit tests:

```bash
xcodebuild -project MacStat.xcodeproj -scheme MacStat -destination 'platform=macOS' test -only-testing:MacStatTests
```

## How it works

- **CPU load** comes from Mach host statistics (`host_statistics` with `HOST_CPU_LOAD_INFO`).
- **Memory** comes from `host_statistics64` with `HOST_VM_INFO64`.
- **Temperatures and fan speed** are read from the System Management Controller (SMC) through IOKit. MacStat discovers the available sensors on first use and averages them per group, so the same build works across Apple Silicon generations.
- **Sampling** runs in a dedicated actor off the main thread. The menu bar image is redrawn only when a displayed value changes.

The app is not sandboxed, because SMC access is not available from the App Sandbox.

## Project structure

```
MacStat/
├── App/            App entry point and dependency wiring
├── Core/           Hardware readers (CPU, memory, SMC), sampling, formatting
├── Features/
│   ├── MenuBar/    Menu bar item model and image rendering
│   ├── Monitor/    Sampling loop and metric history
│   ├── Popover/    Popover UI and metric cards
│   └── Settings/   Settings window, language and launch at login
└── Resources/      String catalogs, app icon, assets
```

The app uses MVVM with dependency injection, `@Observable` models and Swift 6 strict concurrency.
