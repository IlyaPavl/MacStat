# Diagnostics: implementation and validation

All readers, process accounting and history IO run on SystemSampler. No dependencies or network access were added. Battery properties refresh at most every five seconds. Processes refresh every two seconds only while the panel is open. Thermal state uses notifications and does not establish that throttling is occurring.

CPU accounting intentionally differs from the specification: libproc rusage_info user/system counters are nanoseconds, not raw mach absolute ticks. Applying mach_timebase_info again would corrupt the result. Process start time is only compared for identity, to reject PID reuse.

History continues in icon-only mode to support overnight recording. It stores versioned atomic JSON under Application Support/MacStat, minute averages/maxima for 48 hours and raw values in memory for one hour. Missing metric keys remain absent. Graphs split gaps longer than two minutes. Temperature peak lines are dashed. Extremely fragmented history can exceed the approximate 300-point target to preserve gaps. Disk errors keep in-memory data and retry later. Normal quit waits for a flush. Sleep requests a flush, but suspension or forced termination can interrupt it.

## Validation status

Prepared on Linux without Swift, Xcode, IOKit or Instruments. macOS compilation, unit tests, hardware behavior and CPU/IO overhead have NOT been verified. `git diff --check` passes. English and Russian strings are included; other existing languages fall back to English for new text.

Before merging on a Mac:

1. Build/test with Xcode 27: `xcodebuild -project MacStat.xcodeproj -scheme MacStat -destination 'platform=macOS' test -only-testing:MacStatTests`.
2. Inspect `ioreg -rn AppleSmartBattery` and `sysctl kern.memorystatus_vm_pressure_level`. Check signed discharge watts, charging state, adapter watts, missing properties and a desktop without a battery.
3. Compare CPU and physical footprint with Activity Monitor, including multi-core workloads, terminated/inaccessible processes, app helper grouping and reopen/close of panel. CPU is percent of one core.
4. Check thermal badge transitions and conditional high/critical menu bar icon.
5. Restart and exercise sleep/wake, 1/6/24/48-hour ranges, unknown/corrupt files and normal quit. Confirm gaps and temperature peaks survive.
6. Profile panel open/closed and five-minute flushes in Instruments. The low-overhead requirement needs hardware measurements.
7. Review Russian layout, VoiceOver and small displays.
