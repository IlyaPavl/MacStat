import Foundation
import Darwin

nonisolated struct ProcessRow: Identifiable, Sendable {
    let id: String
    let name: String
    var cpu: Double?
    var memory: UInt64
}

/// rusage_info CPU counters are nanoseconds (libproc.h), not raw mach ticks.
nonisolated final class ProcessReader {
    private struct Previous { var cpu: UInt64; var start: UInt64 }
    private var previous: [Int32: Previous] = [:]
    private var previousTime: TimeInterval?

    static func cpuPercent(before: UInt64, after: UInt64, elapsed: TimeInterval) -> Double? {
        guard elapsed > 0, after >= before else { return nil }
        return Double(after - before) / 1e9 / elapsed * 100
    }

    func reset() { previous = [:]; previousTime = nil }

    func read() -> [ProcessRow] {
        let now = ProcessInfo.processInfo.systemUptime
        let required = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard required > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(required) / MemoryLayout<Int32>.size + 128)
        let bytes = pids.withUnsafeMutableBytes { proc_listpids(UInt32(PROC_ALL_PIDS), 0, $0.baseAddress, Int32($0.count)) }
        guard bytes > 0 else { return [] }
        var next: [Int32: Previous] = [:]
        var groups: [String: ProcessRow] = [:]
        for pid in pids.prefix(Int(bytes) / MemoryLayout<Int32>.size) where pid > 0 {
            var info = rusage_info_v4()
            let result = withUnsafeMutablePointer(to: &info) { pointer in
                pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                    proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
                }
            }
            guard result == 0 else { continue }
            let cpu = info.ri_user_time + info.ri_system_time
            next[pid] = Previous(cpu: cpu, start: info.ri_proc_start_abstime)
            var percent: Double?
            if let old = previous[pid], old.start == info.ri_proc_start_abstime, let previousTime {
                percent = Self.cpuPercent(before: old.cpu, after: cpu, elapsed: now - previousTime)
            }
            var pathBuffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
            let pathLength = pathBuffer.withUnsafeMutableBytes { proc_pidpath(pid, $0.baseAddress, UInt32($0.count)) }
            let path = pathLength > 0 ? String(cString: pathBuffer) : ""
            var nameBuffer = [CChar](repeating: 0, count: 1024)
            let nameLength = nameBuffer.withUnsafeMutableBytes { proc_name(pid, $0.baseAddress, UInt32($0.count)) }
            var name = nameLength > 0 ? String(cString: nameBuffer) : "PID \(pid)"
            var key = "pid:\(pid)"
            if let range = path.range(of: ".app/") {
                let app = String(path[..<range.lowerBound]) + ".app"
                key = app
                name = URL(fileURLWithPath: app).deletingPathExtension().lastPathComponent
            }
            if var group = groups[key] {
                if let percent { group.cpu = (group.cpu ?? 0) + percent }
                group.memory += info.ri_phys_footprint
                groups[key] = group
            } else {
                groups[key] = ProcessRow(id: key, name: name, cpu: percent, memory: info.ri_phys_footprint)
            }
        }
        previous = next; previousTime = now
        return Array(groups.values)
    }
}
