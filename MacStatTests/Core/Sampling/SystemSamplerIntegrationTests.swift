//
//  SystemSamplerIntegrationTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Testing
@testable import MacStat

/// Читает настоящее железо: проверяет датчики SMC и статистику Mach на этой машине.
struct SystemSamplerIntegrationTests {
    @Test func samplesRealSensors() async throws {
        let sampler = SystemSampler()
        _ = await sampler.takeSnapshot()
        try await Task.sleep(for: .milliseconds(300))
        let snapshot = await sampler.takeSnapshot()

        let load = try #require(snapshot.cpuLoad)
        #expect((0...1).contains(load))
        let cpuTemperature = try #require(snapshot.cpuTemperature)
        #expect((15...120).contains(cpuTemperature))
        let gpuTemperature = try #require(snapshot.gpuTemperature)
        #expect((15...120).contains(gpuTemperature))
        if let chipPower = snapshot.chipPower {
            #expect((0...500).contains(chipPower))
        }
        if let batteryTemperature = snapshot.batteryTemperature {
            #expect((1...130).contains(batteryTemperature))
        }
        let memory = try #require(snapshot.memoryUsage)
        #expect(memory.usedBytes > 0 && memory.usedBytes <= memory.totalBytes)
    }
}
