//
//  HistoryStoreTests.swift
//  MacStatTests
//

import Foundation
import Testing
@testable import MacStat

/// Каждый тест использует отдельную папку и заданное время, без истории пользователя.
struct HistoryStoreTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func withFile(_ body: (URL) throws -> Void) throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try body(folder.appending(path: "history.json"))
    }

    @Test func averagesEachMetricAndPreservesMaximum() throws {
        try withFile { url in
            let store = HistoryStore(url: url)
            store.record(SystemSnapshot(cpuLoad: 1, cpuTemperature: 60), at: now)
            store.record(SystemSnapshot(cpuLoad: 0, cpuTemperature: 80), at: now.addingTimeInterval(1))
            store.record(SystemSnapshot(cpuLoad: 0.5), at: now.addingTimeInterval(60))
            #expect(store.flush(at: now.addingTimeInterval(61)))
            let saved = try JSONDecoder().decode(HistoryDocument.self, from: Data(contentsOf: url))
            #expect(saved.buckets.count == 2)
            #expect(saved.buckets[0].avg["cpuLoad"] == 0.5)
            #expect(saved.buckets[0].max["cpuLoad"] == 1)
            #expect(saved.buckets[0].avg["cpuTemperature"] == 70)
            #expect(saved.buckets[0].max["cpuTemperature"] == 80)
            #expect(saved.buckets[1].avg["cpuTemperature"] == nil)
            #expect(saved.buckets[0].avg["fanSpeed"] == nil)
        }
    }

    @Test func restartContinuesUnfinishedMinute() throws {
        try withFile { url in
            let original = HistoryStore(url: url)
            original.record(SystemSnapshot(cpuLoad: 1), at: now)
            original.record(SystemSnapshot(cpuLoad: 0), at: now.addingTimeInterval(1))
            #expect(original.flush(at: now.addingTimeInterval(2)))
            let restored = HistoryStore(url: url)
            restored.record(SystemSnapshot(cpuLoad: 0), at: now.addingTimeInterval(3))
            #expect(restored.flush(at: now.addingTimeInterval(4)))
            let saved = try JSONDecoder().decode(HistoryDocument.self, from: Data(contentsOf: url))
            #expect(saved.buckets.count == 1)
            #expect(saved.buckets[0].counts?["cpuLoad"] == 3)
            #expect(abs(Double(saved.buckets[0].avg["cpuLoad"] ?? 0) - 1.0 / 3) < 0.0001)
            #expect(saved.buckets[0].max["cpuLoad"] == 1)
        }
    }

    @Test func automaticallyFlushesEveryFiveMinutes() throws {
        try withFile { url in
            let store = HistoryStore(url: url)
            store.record(SystemSnapshot(cpuLoad: 0.5), at: now)
            store.record(SystemSnapshot(cpuLoad: 0.5), at: now.addingTimeInterval(299))
            #expect(!FileManager.default.fileExists(atPath: url.path))
            store.record(SystemSnapshot(cpuLoad: 0.5), at: now.addingTimeInterval(300))
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }

    @Test func limitsRetentionAndPreservesThermalTransitions() throws {
        try withFile { url in
            let store = HistoryStore(url: url)
            store.record(SystemSnapshot(cpuLoad: 0.5), at: now.addingTimeInterval(-49 * 3600))
            store.thermal(.normal, at: now.addingTimeInterval(-49 * 3600))
            store.record(SystemSnapshot(cpuLoad: 0.8), at: now)
            store.thermal(.high, at: now)
            store.thermal(.high, at: now.addingTimeInterval(1))
            store.thermal(.normal, at: now.addingTimeInterval(2))
            #expect(store.flush(at: now.addingTimeInterval(3)))
            let saved = try JSONDecoder().decode(HistoryDocument.self, from: Data(contentsOf: url))
            #expect(saved.buckets.count == 1)
            #expect(saved.thermalEvents.map(\.state) == [.high, .normal])
        }
    }

    @Test func rejectsCorruptAndUnknownVersionFiles() throws {
        try withFile { url in
            for contents in ["broken", "{\"version\":99,\"buckets\":[],\"thermalEvents\":[]}"] {
                try Data(contents.utf8).write(to: url)
                #expect(HistoryStore(url: url).points(hours: 6, now: now)[.cpuLoad]?.isEmpty == true)
            }
        }
    }

    @Test func keepsUnknownMetricKeysCompatible() throws {
        try withFile { url in
            let document = HistoryDocument(buckets: [HistoryBucket(t: now, avg: ["futureSensor": 1, "cpuLoad": 0.5], max: [:])])
            try JSONEncoder().encode(document).write(to: url)
            let points = HistoryStore(url: url).points(hours: 6, now: now)
            #expect(points[.cpuLoad]?.first?.value == 0.5)
            #expect(points[.fanSpeed]?.isEmpty == true)
        }
    }

    @Test func preservesMissingMetricAndSleepGaps() throws {
        try withFile { url in
            let store = HistoryStore(url: url)
            store.record(SystemSnapshot(cpuLoad: 1, fanSpeed: 1000), at: now)
            store.record(SystemSnapshot(cpuLoad: 0.5), at: now.addingTimeInterval(60))
            store.record(SystemSnapshot(cpuLoad: 0, fanSpeed: 1100), at: now.addingTimeInterval(120))
            store.record(SystemSnapshot(cpuLoad: 1, fanSpeed: 1200), at: now.addingTimeInterval(600))
            let points = store.points(hours: 6, now: now.addingTimeInterval(600))
            #expect(points[.cpuLoad]?.map(\.segment) == [0, 0, 0, 1])
            #expect(points[.fanSpeed]?.map(\.segment) == [0, 1, 2])
        }
    }

    @Test func failedWriteDoesNotDiscardSamples() throws {
        try withFile { url in
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            let store = HistoryStore(url: url)
            store.record(SystemSnapshot(cpuLoad: 1), at: now)
            #expect(!store.flush(at: now))
            try FileManager.default.removeItem(at: url)
            #expect(store.flush(at: now))
            #expect(HistoryStore(url: url).points(hours: 6, now: now)[.cpuLoad]?.first?.value == 1)
        }
    }

    @Test func downsamplingPreservesAveragesPeaksAndSegments() {
        let points: [HistoryPoint] = (0..<600).map { index in
            let gap = index >= 300 ? 600 : 0
            let date = now.addingTimeInterval(Double(index * 60 + gap))
            return HistoryPoint(
                date: date,
                value: Double(index % 2),
                peak: index == 25 ? 99 : 1,
                segment: 0
            )
        }
        let result = HistoryStore.downsample(points)
        #expect(result.count == 300)
        #expect(result.first?.value == 0.5)
        #expect(result.map(\.peak).max() == 99)
        #expect(Set(result.map(\.segment)) == [0, 1])
        #expect(HistoryStore.downsample([]).isEmpty)
    }

    @Test func fragmentedHistoryStaysBoundedWithoutBridgingGaps() {
        let points: [HistoryPoint] = (0..<1000).map { index in
            HistoryPoint(date: now.addingTimeInterval(Double(index * 180)), value: 1, peak: index == 25 ? 99 : 1, segment: index)
        }
        let result = HistoryStore.downsample(points, limit: 300)
        #expect(result.count <= 300)
        #expect(Set(result.map(\.segment)).count == result.count)
        #expect(result.map(\.peak).max() == 99)
    }

}
