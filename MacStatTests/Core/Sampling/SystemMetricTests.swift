//
//  SystemMetricTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Testing
@testable import MacStat

struct SystemMetricTests {
    @Test func readsValueFromSnapshot() {
        let snapshot = SystemSnapshot(
            cpuLoad: 0.25,
            cpuTemperature: 50,
            gpuTemperature: 40,
            fanSpeed: nil,
            memoryUsage: MemoryUsage(usedBytes: 3, totalBytes: 4)
        )
        #expect(SystemMetric.cpuLoad.value(in: snapshot) == 0.25)
        #expect(SystemMetric.gpuTemperature.value(in: snapshot) == 40)
        #expect(SystemMetric.fanSpeed.value(in: snapshot) == nil)
        #expect(SystemMetric.memory.value(in: snapshot) == 0.75)
    }
}
