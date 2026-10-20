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
            batteryTemperature: 31,
            chipPower: 4.5,
            memoryUsage: MemoryUsage(usedBytes: 3, totalBytes: 4)
        )
        #expect(SystemMetric.cpuLoad.value(in: snapshot) == 0.25)
        #expect(SystemMetric.gpuTemperature.value(in: snapshot) == 40)
        #expect(SystemMetric.fanSpeed.value(in: snapshot) == nil)
        #expect(SystemMetric.memory.value(in: snapshot) == 0.75)
        #expect(SystemMetric.batteryTemperature.value(in: snapshot) == 31)
        #expect(SystemMetric.chipPower.value(in: snapshot) == 4.5)
    }

    @Test func onlyHardwareSpecificMetricsAreOptional() {
        let optional = SystemMetric.allCases.filter(\.dependsOnHardware)
        #expect(optional == [.chipPower, .fanSpeed, .batteryTemperature])
    }
}
