import Foundation

nonisolated struct HistoryPoint: Identifiable, Sendable {
    var date: Date
    var value: Double
    var peak: Double
    var segment: Int
    var id: Date { date }
}
nonisolated struct HistoryBucket: Codable, Sendable {
    var t: Date
    var avg: [String: Float]
    var max: [String: Float]
}
nonisolated struct ThermalEvent: Codable, Sendable {
    var date: Date
    var state: ThermalStatus
}
nonisolated struct HistoryDocument: Codable, Sendable {
    var version = 1
    var buckets: [HistoryBucket] = []
    var thermalEvents: [ThermalEvent] = []
}

/// Owned exclusively by SystemSampler. All file IO stays on that actor.
nonisolated final class HistoryStore {
    private let url: URL
    private var document = HistoryDocument()
    private var raw: [(Date, [String: Double])] = []
    private var minute: Date?
    private var sums: [String: Double] = [:]
    private var counts: [String: Int] = [:]
    private var peaks: [String: Float] = [:]
    private var lastFlush = Date()
    private var loaded = false

    init(url: URL = URL.applicationSupportDirectory.appending(path: "MacStat/history.json")) { self.url = url }
    func load() {
        guard !loaded else { return }; loaded = true
        if let data = try? Data(contentsOf: url), let file = try? JSONDecoder().decode(HistoryDocument.self, from: data), file.version == 1 {
            document = file
        }
        prune(now: Date())
    }
    func record(_ snapshot: SystemSnapshot, at now: Date = Date()) {
        load()
        let values = Dictionary(uniqueKeysWithValues: SystemMetric.allCases.compactMap { metric in
            metric.value(in: snapshot).flatMap { $0.isFinite ? (metric.rawValue, $0) : nil }
        })
        let start = Date(timeIntervalSince1970: floor(now.timeIntervalSince1970 / 60) * 60)
        if minute != start { closeMinute(); minute = start }
        for (key, value) in values {
            sums[key, default: 0] += value; counts[key, default: 0] += 1
            peaks[key] = Swift.max(peaks[key] ?? -Float.infinity, Float(value))
        }
        raw.append((now, values)); prune(now: now)
        if now.timeIntervalSince(lastFlush) >= 300 { flush() }
    }
    func thermal(_ state: ThermalStatus, at now: Date = Date()) {
        load()
        guard document.thermalEvents.last?.state != state else { return }
        document.thermalEvents.append(ThermalEvent(date: now, state: state))
        prune(now: now)
    }
    private func currentBucket() -> HistoryBucket? {
        guard let minute, !sums.isEmpty else { return nil }
        return HistoryBucket(t: minute, avg: sums.mapValues { Float($0) }, max: peaks)
    }
    private func averagedBucket() -> HistoryBucket? {
        guard var bucket = currentBucket() else { return nil }
        for (key, sum) in sums { bucket.avg[key] = Float(sum / Double(counts[key, default: 1])) }
        return bucket
    }
    private func closeMinute() {
        if let bucket = averagedBucket() {
            document.buckets.removeAll { $0.t == bucket.t }
            document.buckets.append(bucket)
        }
        sums = [:]; counts = [:]; peaks = [:]
    }
    private func prune(now: Date) {
        document.buckets.removeAll { $0.t < now.addingTimeInterval(-48 * 3600) || $0.t > now }
        document.thermalEvents.removeAll { $0.date < now.addingTimeInterval(-48 * 3600) }
        raw.removeAll { $0.0 < now.addingTimeInterval(-3600) }
    }
    @discardableResult func flush() -> Bool {
        load(); prune(now: Date())
        var file = document
        if let bucket = averagedBucket() {
            file.buckets.removeAll { $0.t == bucket.t }; file.buckets.append(bucket)
        }
        do {
            let data = try JSONEncoder().encode(file)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            lastFlush = Date(); return true
        } catch { return false }
    }
    func points(hours: Int, now: Date = Date()) -> [SystemMetric: [HistoryPoint]] {
        load()
        let cutoff = now.addingTimeInterval(-Double(hours) * 3600)
        var buckets = document.buckets
        if let bucket = averagedBucket() { buckets.removeAll { $0.t == bucket.t }; buckets.append(bucket) }
        return Dictionary(uniqueKeysWithValues: SystemMetric.allCases.map { metric in
            let key = metric.rawValue
            var points = buckets.filter { $0.t >= cutoff && $0.t <= now }.compactMap { bucket -> HistoryPoint? in
                guard let value = bucket.avg[key] else { return nil }
                return HistoryPoint(date: bucket.t, value: Double(value), peak: Double(bucket.max[key] ?? value), segment: 0)
            }
            if hours == 1, let firstRaw = raw.first?.0 {
                points.removeAll { $0.date >= Date(timeIntervalSince1970: floor(firstRaw.timeIntervalSince1970 / 60) * 60) }
                points += raw.compactMap { date, values in values[key].map { HistoryPoint(date: date, value: $0, peak: $0, segment: 0) } }
            }
            return (metric, Self.downsample(points.sorted { $0.date < $1.date }))
        })
    }
    static func downsample(_ points: [HistoryPoint], limit: Int = 300) -> [HistoryPoint] {
        guard !points.isEmpty else { return [] }
        var segmented = points
        var segment = 0
        for index in segmented.indices {
            if index > 0, segmented[index].date.timeIntervalSince(segmented[index - 1].date) > 120 { segment += 1 }
            segmented[index].segment = segment
        }
        let size = Swift.max(1, Int(ceil(Double(points.count) / Double(Swift.max(1, limit)))))
        var result: [HistoryPoint] = []
        var group: [HistoryPoint] = []
        func emit() {
            guard let first = group.first else { return }
            result.append(HistoryPoint(date: first.date, value: group.reduce(0) { $0 + $1.value } / Double(group.count), peak: group.map(\.peak).max() ?? first.peak, segment: first.segment))
            group = []
        }
        for point in segmented {
            if group.count >= size || group.last.map({ $0.segment != point.segment }) == true { emit() }
            group.append(point)
        }
        emit(); return result
    }
}
