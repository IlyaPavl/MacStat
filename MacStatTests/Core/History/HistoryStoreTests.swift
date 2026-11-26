//
//  HistoryStoreTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation
import Testing
@testable import MacStat

struct HistoryStoreTests {
    /// Начало минуты: 1 800 000 000 делится на 60.
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString)/history.json")
    }

    @Test func averagesMinuteAndSurvivesReload() throws {
        let url = makeURL()
        let store = HistoryStore(url: url)
        for (offset, load) in [(0.0, 0.2), (10, 0.4), (20, 0.6), (65, 0.8)] {
            store.record(SystemSnapshot(cpuLoad: load), at: base.addingTimeInterval(offset))
        }
        #expect(store.flush(at: base.addingTimeInterval(70)))

        let reloaded = HistoryStore(url: url)
        let points = try #require(reloaded.points(hours: 1, now: base.addingTimeInterval(120))[.cpuLoad])
        #expect(points.count == 2)
        #expect(abs(points[0].value - 0.4) < 0.001)
        #expect(abs(points[0].peak - 0.6) < 0.001)
        #expect(abs(points[1].value - 0.8) < 0.001)
    }

    @Test func oneHourViewUsesRawSamples() throws {
        let store = HistoryStore(url: makeURL())
        for second in 0..<5 {
            store.record(SystemSnapshot(cpuLoad: 0.5), at: base.addingTimeInterval(Double(second)))
        }
        let points = try #require(store.points(hours: 1, now: base.addingTimeInterval(10))[.cpuLoad])
        #expect(!points.isEmpty)
        #expect(points.allSatisfy { abs($0.value - 0.5) < 0.001 })
    }

    @Test func dropsBucketsOlderThanRetention() throws {
        let store = HistoryStore(url: makeURL())
        store.record(SystemSnapshot(cpuLoad: 0.5), at: base)
        let later = base.addingTimeInterval(49 * 3600)
        store.record(SystemSnapshot(cpuLoad: 0.7), at: later)
        let points = try #require(store.points(hours: 48, now: later)[.cpuLoad])
        #expect(points.count == 1)
    }

    @Test func corruptedFileMeansEmptyHistory() throws {
        let url = makeURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)
        let points = HistoryStore(url: url).points(hours: 1, now: base)
        #expect(points[.cpuLoad]?.isEmpty == true)
    }

    @Test func downsampleAveragesGroupsAndKeepsPeaks() {
        let samples: [(date: Date, value: Double, peak: Double)] = [
            (base, 1, 1), (base.addingTimeInterval(1), 3, 5), (base.addingTimeInterval(30), 10, 10),
        ]
        let points = HistoryStore.downsample(samples, from: base, width: 12)
        #expect(points.count == 2)
        #expect(points[0].value == 2)
        #expect(points[0].peak == 5)
    }

    @Test func downsampleBreaksSegmentsOnLongPauses() {
        let samples: [(date: Date, value: Double, peak: Double)] = [0.0, 10, 20, 1000].map {
            (date: base.addingTimeInterval($0), value: 1, peak: 1)
        }
        let points = HistoryStore.downsample(samples, from: base, width: 12)
        #expect(points.map(\.segment) == [0, 0, 1])
    }
}
