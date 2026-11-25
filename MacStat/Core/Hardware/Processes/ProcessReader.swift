//
//  ProcessReader.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Darwin
import Foundation

/// Обходит процессы через libproc. Вызывается только при открытой панели.
nonisolated final class ProcessReader {
    /// Предыдущий замер процесса и его кэшированная идентичность.
    private struct Entry {
        let start: UInt64
        let cpuTicks: UInt64
        let id: String
        let name: String
    }

    private var previous: [pid_t: Entry] = [:]
    private var previousTime: TimeInterval?
    private let timebase: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    /// Забывает прошлый замер: следующий вызов `read()` снова вернёт `cpu == nil`.
    func reset() {
        previous.removeAll()
        previousTime = nil
    }

    /// Процессы, сгруппированные по приложению. Недоступные и завершившиеся пропускаются.
    func read() -> [ProcessRow] {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = previousTime.map { now - $0 }
        previousTime = now

        var next: [pid_t: Entry] = [:]
        var groups: [String: ProcessRow] = [:]
        for pid in listPIDs() {
            var info = rusage_info_v4()
            let status = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                    proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
                }
            }
            guard status == 0 else { continue }

            let ticks = info.ri_user_time &+ info.ri_system_time
            // Тот же PID с другим временем старта — это уже другой процесс.
            let old = previous[pid].flatMap { $0.start == info.ri_proc_start_abstime ? $0 : nil }
            let (id, name) = old.map { ($0.id, $0.name) } ?? identity(of: pid)
            var cpu: Double?
            if let old, let elapsed {
                cpu = ProcessCPU.percent(
                    before: old.cpuTicks, after: ticks, elapsed: elapsed,
                    numer: timebase.numer, denom: timebase.denom
                )
            }
            next[pid] = Entry(start: info.ri_proc_start_abstime, cpuTicks: ticks, id: id, name: name)

            if var group = groups[id] {
                if let cpu { group.cpu = (group.cpu ?? 0) + cpu }
                group.memory += info.ri_phys_footprint
                groups[id] = group
            } else {
                groups[id] = ProcessRow(id: id, name: name, cpu: cpu, memory: info.ri_phys_footprint)
            }
        }
        previous = next
        return Array(groups.values)
    }

    /// Все PID системы, кроме нулевого.
    private func listPIDs() -> [pid_t] {
        let size = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard size > 0 else { return [] }
        // Запас на процессы, появившиеся между двумя вызовами.
        var pids = [pid_t](repeating: 0, count: Int(size) / MemoryLayout<pid_t>.stride + 32)
        let written = pids.withUnsafeMutableBytes {
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, $0.baseAddress, Int32($0.count))
        }
        guard written > 0 else { return [] }
        return pids.prefix(Int(written) / MemoryLayout<pid_t>.stride).filter { $0 > 0 }
    }

    /// Группа и название: внешнее приложение либо сам процесс. Вызывается один раз на процесс.
    private func identity(of pid: pid_t) -> (id: String, name: String) {
        var path = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        if proc_pidpath(pid, &path, UInt32(path.count)) > 0,
           let app = ProcessCPU.applicationPath(in: Self.string(from: path)) {
            return (app, URL(fileURLWithPath: app).deletingPathExtension().lastPathComponent)
        }
        var name = [CChar](repeating: 0, count: 256)
        let length = proc_name(pid, &name, UInt32(name.count))
        return ("pid:\(pid)", length > 0 ? Self.string(from: name) : "PID \(pid)")
    }

    /// Строка из C-буфера до первого нулевого байта.
    private static func string(from buffer: [CChar]) -> String {
        String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
