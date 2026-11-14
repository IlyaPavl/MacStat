import Foundation
import Testing
@testable import MacStat

struct DiagnosticsTests {
    @Test func cpuCountersAreNanoseconds() {
        #expect(ProcessReader.cpuPercent(before: 1_000_000_000, after: 3_000_000_000, elapsed: 2) == 100)
        #expect(ProcessReader.cpuPercent(before: 0, after: 4_000_000_000, elapsed: 2) == 200)
        #expect(ProcessReader.cpuPercent(before: 10, after: 9, elapsed: 2) == nil)
        #expect(ProcessReader.cpuPercent(before: 0, after: 1, elapsed: 0) == nil)
    }
    @Test func batteryHealthUsesRawCapacity() {
        #expect(BatteryReading.health(maximum: 4550, design: 5000) == 91)
        #expect(BatteryReading.health(maximum: 4550, design: 0) == nil)
        #expect(BatteryReading.health(maximum: nil, design: 5000) == nil)
        #expect(Int64(bitPattern: UInt64.max - 999) == -1000)
    }
    @Test func downsamplingPreservesPeaksAndGaps() {
        let start = Date(timeIntervalSince1970: 0)
        let points = (0..<600).map { index in
            HistoryPoint(date: start.addingTimeInterval(Double(index * 60 + (index >= 300 ? 600 : 0))), value: Double(index % 2), peak: index == 25 ? 99 : 1, segment: 0)
        }
        let result = HistoryStore.downsample(points)
        #expect(result.count == 300)
        #expect(result.first?.value == 0.5)
        #expect(result.map(\.peak).max() == 99)
        #expect(Set(result.map(\.segment)) == Set([0, 1]))
    }
    @Test func persistsBucketsAndHandlesCorruption() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "history.json")
        let store = HistoryStore(url: url)
        let now = Date()
        store.record(SystemSnapshot(cpuLoad: 0.5), at: now.addingTimeInterval(-120))
        store.record(SystemSnapshot(cpuLoad: 1), at: now.addingTimeInterval(-60))
        #expect(store.flush())
        let restored = HistoryStore(url: url).points(hours: 6, now: now)
        #expect(restored[.cpuLoad]?.count == 2)
        #expect(restored[.fanSpeed]?.isEmpty == true)
        try Data("broken".utf8).write(to: url)
        #expect(HistoryStore(url: url).points(hours: 6)[.cpuLoad]?.isEmpty == true)
        try Data("{\"version\":99,\"buckets\":[],\"thermalEvents\":[]}".utf8).write(to: url)
        #expect(HistoryStore(url: url).points(hours: 6)[.cpuLoad]?.isEmpty == true)
    }
}
