//
//  BatteryReadingTests.swift
//  MacStatTests
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation
import Testing
@testable import MacStat

struct BatteryReadingTests {
    @Test func healthIsRawCapacityOverDesign() throws {
        let health = try #require(BatteryReading.health(maximum: 4500, design: 5000))
        #expect(abs(health - 90) < 0.0001)
        #expect(BatteryReading.health(maximum: 0, design: 5000) == nil)
    }

    @Test func dischargeIsNegativeEvenWhenCurrentIsUnsigned() throws {
        let amperage = UInt64(bitPattern: -1000)
        let watts = try #require(BatteryReading.power(voltage: 12_000, amperage: amperage))
        #expect(abs(watts + 12) < 0.0001)
    }

    @Test func decodesIORegistryProperties() throws {
        let reading = BatteryReader.reading(from: [
            "CycleCount": 212,
            "AppleRawMaxCapacity": 4500,
            "DesignCapacity": 5000,
            "Voltage": 12_000,
            "Amperage": NSNumber(value: Int64(-1000)),
            "AdapterDetails": ["Watts": 67],
            "ExternalConnected": true,
            "IsCharging": false,
        ])
        #expect(reading.cycles == 212)
        #expect(reading.adapterWatts == 67)
        #expect(reading.isExternalPowerConnected == true)
        #expect(reading.isCharging == false)
        let watts = try #require(reading.watts)
        let health = try #require(reading.health)
        #expect(abs(watts + 12) < 0.0001)
        #expect(abs(health - 90) < 0.0001)
    }

    @Test func readsCapacitiesNestedInBatteryData() throws {
        let reading = BatteryReader.reading(from: [
            "BatteryData": ["AppleRawMaxCapacity": 8438, "DesignCapacity": 8579],
        ])
        let health = try #require(reading.health)
        #expect(abs(health - 98.356) < 0.001)
    }

    @Test func missingPropertiesStayNil() {
        let reading = BatteryReader.reading(from: [:])
        #expect(reading.isEmpty)
    }
}
