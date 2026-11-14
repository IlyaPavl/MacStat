//
//  HistoryStore.swift
//  MacStat
//

import Foundation

/// Принадлежит SystemSampler: чтение, агрегация и запись выполняются вне главного потока.
nonisolated final class HistoryStore {
    /// Сырые значения хранятся только в памяти за последний час.
    private struct Sample {
        let date: Date
        let values: [String: Double]
    }

    private static let retention: TimeInterval = 48 * 3600
    private static let flushInterval: TimeInterval = 5 * 60
    private let url: URL
    private var document = HistoryDocument()
    private var raw: [Sample] = []
    private var minute: Date?
    private var sums: [String: Double] = [:]
    private var counts: [String: Int] = [:]
    private var peaks: [String: Float] = [:]
    private var lastFlushAttempt: Date?
    private var isLoaded = false
    private var isDirty = false

    /// Другой URL позволяет тестировать историю без пользовательских файлов.
    init(url: URL) {
        self.url = url
        raw.reserveCapacity(3600)
    }

    /// Повреждённый файл и неизвестная версия означают пустую историю.
    func load(at now: Date = Date()) {
        guard !isLoaded else { return }
        isLoaded = true
        lastFlushAttempt = now
        if let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode(HistoryDocument.self, from: data), saved.version == 1 {
            document = saved
            // По одному бакету на минуту, даже если файл содержит дубликаты.
            var unique: [Date: HistoryBucket] = [:]
            for bucket in document.buckets {
                unique[bucket.t] = bucket
            }
            document.buckets = unique.values.sorted { $0.t < $1.t }
        }
        prune(at: now)
    }

    /// Добавляет замер, закрывает прошлую минуту и раз в пять минут сохраняет файл.
    @discardableResult
    func record(_ snapshot: SystemSnapshot, at now: Date = Date()) -> Bool {
        load(at: now)
        let values = Dictionary(uniqueKeysWithValues: SystemMetric.allCases.compactMap { metric in
            metric.value(in: snapshot).flatMap { value in
                value.isFinite && Float(value).isFinite ? (metric.rawValue, value) : nil
            }
        })
        let start = Self.minuteStart(now)
        if minute != start {
            closeMinute()
            beginMinute(start)
        }
        for (key, value) in values {
            sums[key, default: 0] += value
            counts[key, default: 0] += 1
            peaks[key] = Swift.max(peaks[key] ?? -Float.infinity, Float(value))
        }
        raw.append(Sample(date: now, values: values))
        isDirty = true
        prune(at: now)
        let elapsed = now.timeIntervalSince(lastFlushAttempt ?? now)
        if elapsed >= Self.flushInterval || elapsed < 0 {
            return flush(at: now)
        }
        return true
    }

    /// Записывает только смену состояния и время перехода.
    func thermal(_ state: ThermalStatus, at now: Date = Date()) {
        load(at: now)
        guard document.thermalEvents.last?.state != state else { return }
        document.thermalEvents.append(ThermalEvent(date: now, state: state))
        isDirty = true
        prune(at: now)
    }

    /// Включает текущую незакрытую минуту, не сбрасывая её накопленные значения.
    @discardableResult
    func flush(at now: Date = Date()) -> Bool {
        load(at: now)
        prune(at: now)
        lastFlushAttempt = now
        guard isDirty else { return true }
        var saved = document
        if let bucket = currentBucket() {
            saved.buckets.append(bucket)
            saved.buckets.sort { $0.t < $1.t }
        }
        do {
            let data = try JSONEncoder().encode(saved)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            isDirty = false
            return true
        } catch {
            // Сохраняем данные в памяти; повторяем на следующем сбросе, а не каждую секунду.
            return false
        }
    }

    /// Возвращает не более примерно 300 точек на метрику; отсутствие значения разрывает линию.
    func points(hours: Int, now: Date = Date()) -> [SystemMetric: [HistoryPoint]] {
        load(at: now)
        let cutoff = now.addingTimeInterval(-Double(hours) * 3600)
        var buckets = document.buckets
        if let current = currentBucket() {
            buckets.append(current)
        }
        buckets.sort { $0.t < $1.t }
        let rawStart = hours == 1 ? raw.first?.date : nil
        let sources = buckets.filter { bucket in
            bucket.t >= cutoff && bucket.t <= now && (rawStart.map { bucket.t < Self.minuteStart($0) } ?? true)
        }
        return Dictionary(uniqueKeysWithValues: SystemMetric.allCases.map { metric in
            let key = metric.rawValue
            var points: [HistoryPoint] = []
            var segment = 0
            var previousDate: Date?
            var wasMissing = false
            func append(date: Date, value: Double?, peak: Double?) {
                guard let value, value.isFinite else {
                    wasMissing = true
                    return
                }
                if wasMissing || previousDate.map({ date.timeIntervalSince($0) > 120 }) == true {
                    segment += 1
                }
                points.append(HistoryPoint(date: date, value: value, peak: peak ?? value, segment: segment))
                previousDate = date
                wasMissing = false
            }
            for bucket in sources {
                append(date: bucket.t, value: bucket.avg[key].map(Double.init), peak: bucket.max[key].map(Double.init))
            }
            if rawStart != nil {
                for sample in raw where sample.date >= cutoff && sample.date <= now {
                    append(date: sample.date, value: sample.values[key], peak: sample.values[key])
                }
            }
            return (metric, Self.downsample(points))
        })
    }

    /// Усредняет группы, сохраняя пики; группа с пропуском остаётся отдельной точкой.
    static func downsample(_ points: [HistoryPoint], limit: Int = 300) -> [HistoryPoint] {
        guard !points.isEmpty else { return [] }
        let limit = Swift.max(1, limit)
        let size = Swift.max(1, Int(ceil(Double(points.count) / Double(limit))))
        var source = points
        var sourceSegment = 0
        for index in source.indices {
            if index > 0, points[index].segment != points[index - 1].segment
                || points[index].date.timeIntervalSince(points[index - 1].date) > 120 {
                sourceSegment += 1
            }
            source[index].segment = sourceSegment
        }

        var result: [HistoryPoint] = []
        var segment = 0
        var previousEnd: Int?
        var previousWasMixed = false
        for start in stride(from: 0, to: source.count, by: size) {
            let group = source[start..<Swift.min(start + size, source.count)]
            guard let first = group.first, let last = group.last else { continue }
            let isMixed = first.segment != last.segment
            if !result.isEmpty, isMixed || previousWasMixed || previousEnd != first.segment {
                segment += 1
            }
            result.append(HistoryPoint(
                date: first.date,
                value: group.reduce(0) { $0 + $1.value } / Double(group.count),
                peak: group.map(\.peak).max() ?? first.peak,
                segment: segment
            ))
            previousEnd = last.segment
            previousWasMixed = isMixed
        }
        return result
    }

    /// Продолжает текущую минуту из файла, сохраняя её средние и пики после перезапуска.
    private func beginMinute(_ start: Date) {
        minute = start
        if let index = document.buckets.firstIndex(where: { $0.t == start }) {
            let bucket = document.buckets.remove(at: index)
            for (key, value) in bucket.avg where value.isFinite {
                let count = Swift.max(1, bucket.counts?[key] ?? 1)
                counts[key] = count
                sums[key] = Double(value) * Double(count)
                peaks[key] = bucket.max[key].flatMap { $0.isFinite ? $0 : nil } ?? value
            }
        }
    }

    /// Готовит средние текущей минуты с отдельным числом замеров каждой метрики.
    private func currentBucket() -> HistoryBucket? {
        guard let minute, !sums.isEmpty else { return nil }
        let average = sums.map { key, sum in (key, Float(sum / Double(counts[key, default: 1]))) }
        return HistoryBucket(t: minute, avg: Dictionary(uniqueKeysWithValues: average), max: peaks, counts: counts)
    }

    /// Закрывает минуту ровно один раз; изменение системных часов не создаёт дубликаты.
    private func closeMinute() {
        if let bucket = currentBucket() {
            document.buckets.removeAll { $0.t == bucket.t }
            document.buckets.append(bucket)
        }
        sums.removeAll(keepingCapacity: true)
        counts.removeAll(keepingCapacity: true)
        peaks.removeAll(keepingCapacity: true)
    }

    /// Ограничивает срок хранения и отбрасывает значения из будущего после перевода часов.
    private func prune(at now: Date) {
        let oldest = now.addingTimeInterval(-Self.retention)
        let oldCount = document.buckets.count + document.thermalEvents.count
        document.buckets.removeAll { $0.t < oldest || $0.t > now }
        document.thermalEvents.removeAll { $0.date < oldest || $0.date > now }
        raw.removeAll { $0.date < now.addingTimeInterval(-3600) || $0.date > now }
        if let minute, minute < oldest || minute > now {
            isDirty = true
            self.minute = nil
            sums.removeAll(keepingCapacity: true)
            counts.removeAll(keepingCapacity: true)
            peaks.removeAll(keepingCapacity: true)
        }
        if oldCount != document.buckets.count + document.thermalEvents.count {
            isDirty = true
        }
    }

    /// Бакеты привязаны к абсолютным минутам, а не локальному часовому поясу.
    private static func minuteStart(_ date: Date) -> Date {
        Date(timeIntervalSince1970: floor(date.timeIntervalSince1970 / 60) * 60)
    }
}
