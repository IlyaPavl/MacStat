//
//  ProcessCPUTests.swift
//  MacStatTests
//

import Testing
@testable import MacStat

/// Проверяет преобразование единиц, а не показания реального железа.
struct ProcessCPUTests {
    @Test func convertsAppleSiliconTimebase() {
        let value = ProcessCPU.percent(before: 10, after: 48_000_010, elapsed: 2, numerator: 1000, denominator: 24)
        #expect(value == 100)
    }

    @Test func supportsMultipleCores() {
        #expect(ProcessCPU.percent(before: 0, after: 96_000_000, elapsed: 2, numerator: 1000, denominator: 24) == 200)
        #expect(ProcessCPU.percent(before: 0, after: 2_000_000_000, elapsed: 2, numerator: 1, denominator: 1) == 100)
    }

    @Test func rejectsInvalidDeltas() {
        #expect(ProcessCPU.percent(before: 10, after: 9, elapsed: 2, numerator: 1, denominator: 1) == nil)
        #expect(ProcessCPU.percent(before: 0, after: 1, elapsed: 0, numerator: 1, denominator: 1) == nil)
        #expect(ProcessCPU.percent(before: 0, after: 1, elapsed: .nan, numerator: 1, denominator: 1) == nil)
        #expect(ProcessCPU.percent(before: 0, after: 1, elapsed: 1, numerator: 1, denominator: 0) == nil)
    }

    @Test func groupsNestedHelpersByOuterApplication() {
        #expect(ProcessCPU.applicationPath(in: "/Applications/Browser.app/Contents/Frameworks/Helper.app/Contents/MacOS/Helper") == "/Applications/Browser.app")
        #expect(ProcessCPU.applicationPath(in: "/usr/bin/yes") == nil)
        #expect(ProcessCPU.applicationPath(in: "/tmp/not.application/worker") == nil)
    }
}
