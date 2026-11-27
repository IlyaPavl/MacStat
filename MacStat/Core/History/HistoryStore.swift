//
//  HistoryStore.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation

/// Точка графика после усреднения; `segment` отделяет непрерывные участки друг от друга.
nonisolated struct HistoryPoint: Identifiable, Equatable, Sendable {
    /// Время первого замера интервала.
    let date: Date
    /// Среднее за интервал.
    let value: Double
    /// Максимум за интервал.
    let peak: Double
    /// Номер непрерывного участка линии.
    let segment: Int

    /// Время уникально в пределах одной метрики.
    var id: Date { date }
}

/// История метрик: сырые замеры за последний час в памяти и минутные бакеты за 48 часов на диске.
/// Не потокобезопасна сама по себе: доступ идёт через `HistoryRecorder`.
nonisolated final class HistoryStore {
    /// Минута: среднее и максимум каждой метрики, у которой были значения.
    private struct Bucket: Codable {
        var t: Date
        var avg: [String: Float]
        var max: [String: Float]
    }

    /// Формат файла; другая версия читается как пустая история.
    private struct Document: Codable {
        var version = 1
        var buckets: [Bucket] = []
    }

    /// Сырой замер; значения в порядке `metrics`, `.nan` — значения нет.
    private struct Sample {
        let date: Date
        let values: [Float]
    }

    /// Группа замеров одного временного интервала при уменьшении числа точек.
    private struct Bin {
        var index: Int
        var date: Date
        var sum: Double
        var peak: Double
        var count: Int
    }

    /// Порядок метрик в сырых замерах и накопителях.
    private static let metrics = SystemMetric.allCases
    /// Срок хранения минутных бакетов.
    private static let retention: TimeInterval = 48 * 3600
    /// Сколько хранятся сырые замеры.
    private static let rawWindow: TimeInterval = 3600
    /// Как часто история пишется на диск.
    private static let flushInterval: TimeInterval = 5 * 60
    /// Пауза между точками, после которой линия разрывается (сон, выключение).
    private static let gap: TimeInterval = 120
    /// Предел точек на метрику для графика.
    private static let maxPoints = 300

    /// Файл истории.
    private let url: URL
    /// Закрытые минуты за 48 часов.
    private var buckets: [Bucket] = []
    /// Сырые замеры за последний час.
    private var raw: [Sample] = []
    /// Файл уже прочитан.
    private var isLoaded = false
    /// Есть несохранённые изменения.
    private var isDirty = false
    /// Время последней записи на диск.
    private var lastFlush = Date()

    /// Накопитель текущей минуты, индексы совпадают с `metrics`.
    private var minute: Date?
    /// Суммы значений текущей минуты.
    private var sums = [Double](repeating: 0, count: HistoryStore.metrics.count)
    /// Число значений текущей минуты.
    private var counts = [Int](repeating: 0, count: HistoryStore.metrics.count)
    /// Максимумы текущей минуты.
    private var peaks = [Float](repeating: -.infinity, count: HistoryStore.metrics.count)

    /// Другой URL позволяет тестировать историю, не трогая файл пользователя.
    init(url: URL) {
        self.url = url
    }

    /// Добавляет замер; раз в пять минут сохраняет файл.
    func record(_ snapshot: SystemSnapshot, at now: Date = Date()) {
        loadIfNeeded(now)
        let values = Self.metrics.map { metric -> Float in
            guard let value = metric.value(in: snapshot), value.isFinite else { return .nan }
            return Float(value)
        }

        let start = Self.minuteStart(now)
        if start != minute {
            closeMinute()
            minute = start
            trim(now)
        } else if let last = raw.last, last.date > now {
            trim(now) // часы перевели назад
        }

        raw.append(Sample(date: now, values: values))
        for (index, value) in values.enumerated() where !value.isNaN {
            sums[index] += Double(value)
            counts[index] += 1
            peaks[index] = max(peaks[index], value)
        }
        isDirty = true

        let sinceFlush = now.timeIntervalSince(lastFlush)
        if sinceFlush >= Self.flushInterval || sinceFlush < 0 {
            flush(at: now)
        }
    }

    /// Записывает закрытые минуты и текущую неполную. Нужен при сне и выходе.
    @discardableResult
    func flush(at now: Date = Date()) -> Bool {
        loadIfNeeded(now)
        lastFlush = now
        guard isDirty else { return true }
        var saved = buckets
        if let current = currentBucket() {
            saved.removeAll { $0.t == current.t }
            saved.append(current)
        }
        saved.sort { $0.t < $1.t }
        do {
            let data = try JSONEncoder().encode(Document(buckets: saved))
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            isDirty = false
            return true
        } catch {
            return false // данные остаются в памяти, повтор при следующем сбросе
        }
    }

    /// Не более 300 точек на метрику за выбранный период. Для 1 ч свежие минуты берутся из сырых замеров.
    func points(hours: Int, now: Date = Date()) -> [SystemMetric: [HistoryPoint]] {
        loadIfNeeded(now)
        let cutoff = now.addingTimeInterval(-Double(hours) * 3600)
        let useRaw = hours == 1 && !raw.isEmpty

        var minutes = buckets
        if let current = currentBucket() {
            minutes.removeAll { $0.t == current.t }
            minutes.append(current)
        }
        let rawStart = raw.first.map { Self.minuteStart($0.date) }
        minutes = minutes
            .filter { $0.t >= cutoff && $0.t <= now && (useRaw ? $0.t < (rawStart ?? .distantFuture) : true) }
            .sorted { $0.t < $1.t }
        let samples = useRaw ? raw.filter { $0.date >= cutoff && $0.date <= now } : []

        let width = Double(hours) * 3600 / Double(Self.maxPoints)
        var result: [SystemMetric: [HistoryPoint]] = [:]
        for (index, metric) in Self.metrics.enumerated() {
            var source: [(date: Date, value: Double, peak: Double)] = []
            for bucket in minutes {
                guard let average = bucket.avg[metric.rawValue] else { continue }
                source.append((bucket.t, Double(average), Double(bucket.max[metric.rawValue] ?? average)))
            }
            for sample in samples where !sample.values[index].isNaN {
                source.append((sample.date, Double(sample.values[index]), Double(sample.values[index])))
            }
            result[metric] = Self.downsample(source, from: cutoff, width: width)
        }
        return result
    }

    /// Усредняет значения по интервалам `width` секунд, сохраняя максимум; большие паузы начинают новый сегмент.
    static func downsample(
        _ samples: [(date: Date, value: Double, peak: Double)],
        from start: Date,
        width: TimeInterval
    ) -> [HistoryPoint] {
        guard width > 0 else { return [] }
        let maxGap = max(gap, width * 2)
        var points: [HistoryPoint] = []
        var segment = 0

        func append(_ bin: Bin) {
            if let last = points.last, bin.date.timeIntervalSince(last.date) > maxGap {
                segment += 1
            }
            points.append(HistoryPoint(date: bin.date, value: bin.sum / Double(bin.count), peak: bin.peak, segment: segment))
        }

        var current: Bin?
        for sample in samples {
            let index = Int((sample.date.timeIntervalSince(start) / width).rounded(.down))
            if var bin = current, bin.index == index {
                bin.sum += sample.value
                bin.peak = max(bin.peak, sample.peak)
                bin.count += 1
                current = bin
            } else {
                if let current { append(current) }
                current = Bin(index: index, date: sample.date, sum: sample.value, peak: sample.peak, count: 1)
            }
        }
        if let current { append(current) }
        return points
    }

    /// Неполная текущая минута; `nil`, если замеров ещё не было.
    private func currentBucket() -> Bucket? {
        guard let minute else { return nil }
        var average: [String: Float] = [:]
        var peak: [String: Float] = [:]
        for (index, metric) in Self.metrics.enumerated() where counts[index] > 0 {
            average[metric.rawValue] = Float(sums[index] / Double(counts[index]))
            peak[metric.rawValue] = peaks[index]
        }
        return average.isEmpty ? nil : Bucket(t: minute, avg: average, max: peak)
    }

    /// Переносит накопленную минуту в бакеты. Перезапуск внутри одной минуты заменяет её бакет.
    private func closeMinute() {
        if let bucket = currentBucket() {
            buckets.removeAll { $0.t == bucket.t }
            buckets.append(bucket)
        }
        sums = [Double](repeating: 0, count: HistoryStore.metrics.count)
        counts = [Int](repeating: 0, count: HistoryStore.metrics.count)
        peaks = [Float](repeating: -.infinity, count: HistoryStore.metrics.count)
    }

    /// Срок хранения, а также значения «из будущего» после перевода часов. Вызывается раз в минуту.
    private func trim(_ now: Date) {
        let oldest = now.addingTimeInterval(-Self.retention)
        let rawOldest = now.addingTimeInterval(-Self.rawWindow)
        buckets.removeAll { $0.t < oldest || $0.t > now }
        raw.removeAll { $0.date < rawOldest || $0.date > now }
    }

    /// Файл читается один раз; повреждённый или неизвестной версии означает пустую историю.
    private func loadIfNeeded(_ now: Date) {
        guard !isLoaded else { return }
        isLoaded = true
        lastFlush = now
        if let data = try? Data(contentsOf: url),
           let document = try? JSONDecoder().decode(Document.self, from: data),
           document.version == 1 {
            buckets = document.buckets
        }
        trim(now)
    }

    /// Бакеты привязаны к абсолютным минутам, а не к часовому поясу.
    private static func minuteStart(_ date: Date) -> Date {
        Date(timeIntervalSince1970: (date.timeIntervalSince1970 / 60).rounded(.down) * 60)
    }
}
