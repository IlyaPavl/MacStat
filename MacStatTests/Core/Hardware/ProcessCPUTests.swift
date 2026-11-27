//
//  ProcessCPUTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Testing
@testable import MacStat

struct ProcessCPUTests {
    @Test func convertsTicksWithAppleSiliconTimebase() throws {
        // 125/3: одна секунда CPU — 24 млн тиков.
        let percent = try #require(ProcessCPU.percent(before: 0, after: 24_000_000, elapsed: 1, numer: 125, denom: 3))
        #expect(abs(percent - 100) < 0.0001)
    }

    @Test func ignoresCounterRollbackAndInvalidTime() {
        #expect(ProcessCPU.percent(before: 10, after: 5, elapsed: 1, numer: 1, denom: 1) == nil)
        #expect(ProcessCPU.percent(before: 0, after: 5, elapsed: 0, numer: 1, denom: 1) == nil)
        #expect(ProcessCPU.percent(before: 0, after: 5, elapsed: 1, numer: 1, denom: 0) == nil)
    }

    @Test func groupsHelpersByOuterApplication() {
        let helper = "/Applications/Google Chrome.app/Contents/Frameworks/Helper.app/Contents/MacOS/Helper"
        #expect(ProcessCPU.applicationPath(in: helper) == "/Applications/Google Chrome.app")
        #expect(ProcessCPU.applicationPath(in: "/usr/sbin/cfprefsd") == nil)
    }
}
