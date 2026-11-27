# MacStat

A lightweight menu bar monitor for Apple Silicon Macs: CPU load, CPU and GPU temperature, chip power, fan speed, battery temperature and memory use, right next to the clock.

![MacStat in the menu bar](docs/screenshots/menubar.png)

## Features

- **Live menu bar readings.** Pick the metrics you want and the order they appear in. Show each one on its own, or stack two in a single column to save space.
- **Three menu bar styles:** two rows, icons and values, or icon only. Compact and standard density.
- **Popover with history.** Click the menu bar item to see every metric in a glass card with a chart for the last 1, 6, 24 or 48 hours. History survives app restarts, the line breaks where the Mac was asleep, and temperature charts show peaks as a dashed line on longer ranges.
- **Thermal state.** A colored badge shows whether macOS considers the Mac hot. A thermometer appears in the menu bar only when the state is high or critical.
- **Memory pressure.** The memory card shows the system pressure level along with swap and compressed memory, because used memory alone says little on macOS.
- **Battery details.** Health, charge cycles, charging state, battery power in watts and adapter wattage. The section is hidden on Macs without a battery.
- **Top processes.** The three apps using the most CPU and memory, with helper processes counted under their app. The list refreshes only while the popover is open.
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
- **Chip power** is the SMC estimate of the power the whole chip dissipates (`PHPC`), in watts.
- **Battery temperature** averages the SMC battery sensors (`TB0T`, `TB1T`…). It is hidden on Macs without a battery, just like fan speed on Macs without a fan.
- **Thermal state** is `ProcessInfo.thermalState`, checked with every sample.
- **Memory pressure** comes from `kern.memorystatus_vm_pressure_level`, swap from `vm.swapusage`, and compressed memory from the VM compressor page count.
- **Battery details** are read from the `AppleSmartBattery` service in the IORegistry.
- **Top processes** use `libproc` (`proc_listpids`, `proc_pid_rusage`). CPU time is converted with `mach_timebase_info` and shown as a percentage of one core, so it can exceed 100%. Memory is the physical footprint, as in Activity Monitor.
- **History** is kept in detail for the last hour and per minute for 48 hours, with up to 300 averaged points per chart. It is saved to `~/Library/Application Support/MacStat/history.json` every few minutes, on sleep and on quit. A damaged file starts an empty history.
- **Sampling** runs in a dedicated actor off the main thread. The menu bar image is redrawn only when a displayed value changes. With the popover closed and no values in the menu bar, samples are taken every 5 seconds at most.

The app is not sandboxed, because SMC access is not available from the App Sandbox.

## Project structure

```
MacStat/
├── App/            App entry point and dependency wiring
├── Core/           Hardware readers (CPU, memory, SMC, battery, processes), sampling, history, formatting
├── Features/
│   ├── MenuBar/    Menu bar item model and image rendering
│   ├── Monitor/    Sampling loop and metric history
│   ├── Popover/    Popover UI and metric cards
│   └── Settings/   Settings window, language and launch at login
└── Resources/      String catalogs, app icon, assets
```

The app uses MVVM with dependency injection, `@Observable` models and Swift 6 strict concurrency.

## License

MacStat is available under the MIT License. See [LICENSE](LICENSE) for details.
