//
//  BatteryReader.swift
//  MacStat
//
//  Created by Ilya Pavlov on 27.11.2026.
//

import Foundation
import IOKit

/// Читает свойства `AppleSmartBattery` из IORegistry.
nonisolated struct BatteryReader {
    /// `nil` на Mac без батареи.
    func read() -> BatteryReading? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dictionary = properties?.takeRetainedValue() as? [String: Any] else { return nil }
        return Self.reading(from: dictionary)
    }

    /// Разбор отделён от IOKit, чтобы проверять его на сохранённом выводе `ioreg`.
    static func reading(from properties: [String: Any]) -> BatteryReading {
        // На части Mac ёмкости лежат только во вложенном `BatteryData`.
        let batteryData = properties["BatteryData"] as? [String: Any] ?? [:]
        func number(_ key: String) -> NSNumber? {
            properties[key] as? NSNumber ?? batteryData[key] as? NSNumber
        }
        let adapterWatts = (properties["AdapterDetails"] as? [String: Any])?["Watts"] as? NSNumber
        return BatteryReading(
            cycles: number("CycleCount")?.intValue,
            health: BatteryReading.health(
                maximum: number("AppleRawMaxCapacity")?.doubleValue,
                design: number("DesignCapacity")?.doubleValue
            ),
            watts: BatteryReading.power(
                voltage: number("Voltage")?.doubleValue,
                amperage: number("Amperage")?.uint64Value
            ),
            adapterWatts: adapterWatts.map(\.doubleValue).flatMap { $0 > 0 ? $0 : nil },
            isExternalPowerConnected: number("ExternalConnected")?.boolValue,
            isCharging: number("IsCharging")?.boolValue
        )
    }
}
