//
//  MemoryReader.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Darwin
import Foundation

/// Считает занятую память как Мониторинг системы: приложения + wired + сжатая.
nonisolated final class MemoryReader {
    /// Mach-порт хоста для `host_statistics64`.
    private let hostPort = mach_host_self()
    /// Размер страницы памяти, байт.
    private let pageSize = UInt64(getpagesize())
    /// Объём физической памяти, байт.
    private let physicalMemory = ProcessInfo.processInfo.physicalMemory

    deinit {
        mach_port_deallocate(mach_task_self_, hostPort)
    }

    /// Текущее использование памяти.
    func readUsage() -> MemoryUsage? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let status = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return nil }
        let internalPages = UInt64(stats.internal_page_count)
        let purgeablePages = UInt64(stats.purgeable_count)
        let appPages = internalPages > purgeablePages ? internalPages - purgeablePages : 0
        let usedPages = appPages + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        var swap = xsw_usage()
        var swapSize = MemoryLayout.size(ofValue: swap)
        let hasSwap = sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0) == 0
        return MemoryUsage(
            usedBytes: min(usedPages * pageSize, physicalMemory),
            totalBytes: physicalMemory,
            pressure: readPressure(),
            swapBytes: hasSwap ? swap.xsu_used : nil,
            compressedBytes: UInt64(stats.compressor_page_count) * pageSize
        )
    }

    /// Значение sysctl: normal=1, warning=2, critical=4; неизвестное скрываем.
    private func readPressure() -> MemoryPressure? {
        var level: Int32 = 0
        var size = MemoryLayout.size(ofValue: level)
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else { return nil }
        return MemoryPressure(rawValue: Int(level))
    }
}
