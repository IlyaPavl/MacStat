//
//  BatteryReaderTests.swift
//  MacStatTests
//

import Foundation
import Testing
@testable import MacStat

/// Проверяет декодирование реестра без зависимости от наличия батареи на машине.
struct BatteryReaderTests {
    @Test func usesRawCapacityInsteadOfPercentage() {
        let reading = BatteryReader.reading(from: [
            "AppleRawMaxCapacity": 4550,
            "DesignCapacity": 5000,
            "MaxCapacity": 91,
            "CycleCount": 212,
            "Voltage": 12_000,
            "Amperage": NSNumber(value: UInt64(bitPattern: -1000)),
            "ExternalConnected": false,
            "IsCharging": false,
        ])
        #expect(reading.health == 91)
        #expect(reading.cycles == 212)
        #expect(reading.watts == -12)
        #expect(reading.external == false)
        #expect(reading.adapterWatts == nil)
    }

    @Test func missingPropertiesRemainUnknown() {
        let reading = BatteryReader.reading(from: [:])
        #expect(reading.health == nil)
        #expect(reading.cycles == nil)
        #expect(reading.watts == nil)
        #expect(reading.external == nil)
        #expect(reading.charging == nil)
    }

    @Test func readsAdapterRatingSeparatelyFromActualBatteryPower() {
        let reading = BatteryReader.reading(from: [
            "AdapterDetails": ["Watts": 67],
            "ExternalConnected": true,
            "IsCharging": true,
            "Voltage": 14_000,
            "Amperage": 2000,
        ])
        #expect(reading.adapterWatts == 67)
        #expect(reading.watts == 28)
    }
}
