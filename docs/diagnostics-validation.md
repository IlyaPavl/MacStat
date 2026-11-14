# Diagnostics: implementation and validation

## Repository conventions

The base commit and PR branch contain no AGENTS.md, CONTRIBUTING or separate style guide. This change follows the existing layout and code: hardware readers under Core/Hardware, Sendable snapshots under Core/Sampling, UI under Features/Popover, @Observable main-actor models, explicit SystemSampling injection and Russian documentation comments. The app remains native, offline and free of third-party dependencies.

## Runtime behavior

All hardware readers, process accounting, history aggregation and file IO run on SystemSampler. Battery properties refresh at most every five seconds. Processes refresh every two seconds only while the panel is open, with names/paths cached for surviving processes. Closing the panel or entering sleep cancels process sampling; reopening resets CPU deltas. Missing hardware fields remain absent, including unknown power state.

Thermal state uses notifications and does not establish that throttling is occurring. Only serious/critical states add width to the single template menu-bar image. The memory strip uses the discrete sysctl pressure level; zero swap is not treated as a fault.

CPU deltas are converted from mach absolute ticks with mach_timebase_info, as required by the specification. The source contract was checked against Apple's XNU implementation: [fill_task_rusage](https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/kern/bsd_kern.c) copies task_power_info total_user/total_system, and [task_power_info_locked](https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/kern/task.c) obtains them from rm_time_mach. The unit test explicitly exercises a 1000/24 timebase, not only 1/1. A changed process start timestamp invalidates its previous CPU baseline.

History continues in icon-only mode to support overnight recording. Version 1 JSON contains minute averages, maxima and per-metric sample counts, plus thermal transition events. Sample counts allow the unfinished minute to continue after restart; old version 1 buckets without counts remain readable. Unknown metric keys do not break decoding. Writes are atomic every five minutes and on sleep/normal quit. Failed writes keep in-memory data, log to Console and retry on the next flush rather than on every sample. Normal quit waits for the flush without blocking the main thread.

Charts use real timestamps, split both sleep gaps over two minutes and missing metric intervals, preserve temperature maxima and downsample to at most 300 points. An aggregate that spans a gap is drawn as an isolated point, with no line through it; its maximum is preserved. Header, range picker and footer stay visible while the panel scrolls; panel height is constrained to the screen. New strings cover English, Russian, French, Spanish, Arabic and Traditional Chinese. New status data are also included in Copy summary.

## Automated validation

- Passed: Swift 6.2 syntax parsing of all 78 application and test Swift files.
- Passed: 16 portable Swift Testing tests for the actual history, CPU conversion and battery calculation source files, using MainActor default isolation and NonisolatedNonsendingByDefault as in the app. Linux Foundation lacks LocalizedStringResource, so the temporary test target aliases only that localization type to String; this does not test UI or localization behavior.
- Cases cover non-1:1 timebase, multi-core CPU, invalid deltas, helper bundle paths, raw battery health, signed discharge power, minute averages/maxima, restart within the same minute, automatic flush, retention, thermal transitions, corrupt/unknown-version files, unknown metric keys, missing metric/sleep gaps, failed writes and downsampling.
- Passed: JSON validity, all 27 new keys in six languages, matching localization placeholders and preservation of every original translation.
- Passed: git diff --check.

The temporary Linux test target is outside the repository and adds no runtime dependency or supported app platform. Separate macOS tests cover IOKit property decoding and the menu-bar warning image.

## Still requires a Mac

No macOS build, AppKit/SwiftUI type-check, hardware or Instruments test has been performed in this Linux environment. Before merging:

1. With Xcode 27 run `xcodebuild -project MacStat.xcodeproj -scheme MacStat -destination 'platform=macOS' test -only-testing:MacStatTests`. The existing SMC integration test needs a supported physical Apple Silicon Mac. It now uses a temporary history URL and does not touch user history.
2. Inspect `ioreg -rn AppleSmartBattery` and `sysctl kern.memorystatus_vm_pressure_level`. Check signed discharge watts, charging state, adapter watts, missing properties and a desktop without a battery.
3. Compare CPU and physical footprint with Activity Monitor, including multi-core workloads, terminated/inaccessible processes, helper grouping and panel reopening. CPU is percent of one core.
4. Check thermal notification transitions and the conditional menu-bar image.
5. Restart and exercise sleep/wake, all ranges and normal quit. A sleep notification requests a flush, but suspension or forced termination can interrupt it; no samples can be recorded while the Mac is asleep or powered off.
6. Profile panel open/closed and five-minute flushes in Instruments. The low-overhead requirement needs hardware measurements.
7. Review all languages, RTL layout, VoiceOver and small displays.
