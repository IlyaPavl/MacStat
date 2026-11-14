//
//  BatteryReadingTests.swift
//  MacStatTests
//

import Testing
@testable import MacStat

/// Проверяет сырые единицы ёмкости и знаковое представление тока.
struct BatteryReadingTests {
    @Test func healthUsesRawCapacity() {
        #expect(BatteryReading.health(maximum: 4550, design: 5000) == 91)
        #expect(BatteryReading.health(maximum: 5100, design: 5000) == 102)
        #expect(BatteryReading.health(maximum: 4550, design: 0) == nil)
        #expect(BatteryReading.health(maximum: nil, design: 5000) == nil)
        #expect(BatteryReading.health(maximum: .nan, design: 5000) == nil)
    }

    @Test func decodesSignedDischargePower() {
        #expect(BatteryReading.power(voltage: 12_000, amperage: UInt64(bitPattern: -1000)) == -12)
        #expect(BatteryReading.power(voltage: 12_000, amperage: 2000) == 24)
        #expect(BatteryReading.power(voltage: 12_000, amperage: 0) == 0)
        #expect(BatteryReading.power(voltage: nil, amperage: 0) == nil)
    }
}
