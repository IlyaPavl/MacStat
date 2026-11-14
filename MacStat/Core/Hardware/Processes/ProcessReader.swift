//
//  ProcessReader.swift
//  MacStat
//

import Darwin
import Foundation

/// Обходит процессы только по запросу открытой панели; принадлежит SystemSampler.
nonisolated final class ProcessReader {
    /// Предыдущий замер вместе с идентичностью процесса и кэшированным именем.
    private struct Previous {
        let cpu: UInt64
        let start: UInt64
        let time: TimeInterval
        let id: String
        let name: String
    }

    private var previous: [Int32: Previous] = [:]
    private let timebase: mach_timebase_info_data_t

    /// Читает коэффициент перевода mach ticks в наносекунды один раз.
    init() {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        self.timebase = timebase
    }

    /// При повторном открытии панели первый CPU-замер снова остаётся пустым.
    func reset() {
        previous.removeAll(keepingCapacity: true)
    }

    /// Ошибки доступа и завершившиеся процессы пропускаются.
    func read() -> [ProcessRow] {
        let required = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard required > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(required) / MemoryLayout<Int32>.size + 128)
        let bytes = pids.withUnsafeMutableBytes {
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, $0.baseAddress, Int32($0.count))
        }
        guard bytes > 0 else { return [] }

        var next: [Int32: Previous] = [:]
        var groups: [String: ProcessRow] = [:]
        for pid in pids.prefix(min(Int(bytes) / MemoryLayout<Int32>.size, pids.count)) where pid > 0 {
            var info = rusage_info_v4()
            let result = withUnsafeMutablePointer(to: &info) { pointer in
                pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                    proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
                }
            }
            guard result == 0 else { continue }
            let now = ProcessInfo.processInfo.systemUptime
            let (cpu, overflow) = info.ri_user_time.addingReportingOverflow(info.ri_system_time)
            guard !overflow else { continue }
            let old = previous[pid].flatMap { $0.start == info.ri_proc_start_abstime ? $0 : nil }
            let identity = old.map { ($0.id, $0.name) } ?? processIdentity(pid: pid)
            let percent = old.flatMap {
                ProcessCPU.percent(
                    before: $0.cpu,
                    after: cpu,
                    elapsed: now - $0.time,
                    numerator: timebase.numer,
                    denominator: timebase.denom
                )
            }
            next[pid] = Previous(cpu: cpu, start: info.ri_proc_start_abstime, time: now, id: identity.0, name: identity.1)
            if var group = groups[identity.0] {
                if let percent {
                    group.cpu = (group.cpu ?? 0) + percent
                }
                group.memory += info.ri_phys_footprint
                groups[identity.0] = group
            } else {
                groups[identity.0] = ProcessRow(id: identity.0, name: identity.1, cpu: percent, memory: info.ri_phys_footprint)
            }
        }
        previous = next
        return Array(groups.values)
    }

    /// Системные вызовы имени и пути нужны только для новых процессов.
    private func processIdentity(pid: Int32) -> (String, String) {
        var pathBuffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
        let pathLength = pathBuffer.withUnsafeMutableBytes {
            proc_pidpath(pid, $0.baseAddress, UInt32($0.count))
        }
        if pathLength > 0, let path = ProcessCPU.applicationPath(in: String(cString: pathBuffer)) {
            return (path, URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent)
        }
        var nameBuffer = [CChar](repeating: 0, count: 1024)
        let nameLength = nameBuffer.withUnsafeMutableBytes {
            proc_name(pid, $0.baseAddress, UInt32($0.count))
        }
        let name = nameLength > 0 ? String(cString: nameBuffer) : "PID \(pid)"
        return ("pid:\(pid)", name)
    }
}
