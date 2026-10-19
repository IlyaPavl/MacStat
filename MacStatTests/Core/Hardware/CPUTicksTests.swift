//
//  CPUTicksTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import Testing
@testable import MacStat

struct CPUTicksTests {
    @Test func loadIsBusyShareOfDelta() throws {
        let old = CPUTicks(user: 100, system: 50, idle: 800, nice: 0)
        let new = CPUTicks(user: 130, system: 60, idle: 860, nice: 0)
        let load = try #require(CPUTicks.busyFraction(from: old, to: new))
        #expect(abs(load - 0.4) < 0.0001)
    }

    @Test func loadHandlesCounterWraparound() throws {
        let old = CPUTicks(user: .max - 9, system: 0, idle: 0, nice: 0)
        let new = CPUTicks(user: 10, system: 0, idle: 20, nice: 0)
        let load = try #require(CPUTicks.busyFraction(from: old, to: new))
        #expect(abs(load - 0.5) < 0.0001)
    }

    @Test func loadIsNilWithoutElapsedTicks() {
        let ticks = CPUTicks(user: 1, system: 1, idle: 1, nice: 1)
        #expect(CPUTicks.busyFraction(from: ticks, to: ticks) == nil)
    }
}
