//
//  CPULoadReader.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Darwin

/// Считает общую загрузку CPU по разнице тиков между вызовами.
nonisolated final class CPULoadReader {
    /// Mach-порт хоста для `host_statistics`.
    private let hostPort = mach_host_self()
    /// Тики с прошлого вызова.
    private var previousTicks: CPUTicks?

    deinit {
        mach_port_deallocate(mach_task_self_, hostPort)
    }

    /// Загрузка 0...1 с прошлого вызова; первый вызов — `nil`.
    func readLoad() -> Double? {
        guard let currentTicks = fetchTicks() else { return nil }
        defer { previousTicks = currentTicks }
        guard let previousTicks else { return nil }
        return CPUTicks.busyFraction(from: previousTicks, to: currentTicks)
    }

    /// Текущие накопленные тики всех ядер.
    private func fetchTicks() -> CPUTicks? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(hostPort, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return nil }
        return CPUTicks(
            user: info.cpu_ticks.0,
            system: info.cpu_ticks.1,
            idle: info.cpu_ticks.2,
            nice: info.cpu_ticks.3
        )
    }
}
