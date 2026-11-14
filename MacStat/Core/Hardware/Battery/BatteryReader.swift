//
//  BatteryReader.swift
//  MacStat
//

import Foundation
import IOKit

/// Читает AppleSmartBattery; вызывается только из актора сэмплинга.
nonisolated struct BatteryReader {
    /// На настольном Mac без батареи возвращает `nil`.
    func read() -> BatteryReading? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let properties = properties?.takeRetainedValue() as? [String: Any] else { return nil }
        return Self.reading(from: properties)
    }

    /// Отделяет декодирование свойств от IOKit для проверки на сохранённых данных.
    static func reading(from properties: [String: Any]) -> BatteryReading {
        func number(_ key: String) -> NSNumber? {
            properties[key] as? NSNumber
        }
        let adapter = properties["AdapterDetails"] as? [String: Any]
        return BatteryReading(
            cycles: number("CycleCount").flatMap { $0.intValue >= 0 ? $0.intValue : nil },
            health: BatteryReading.health(
                maximum: number("AppleRawMaxCapacity")?.doubleValue,
                design: number("DesignCapacity")?.doubleValue
            ),
            watts: BatteryReading.power(
                voltage: number("Voltage")?.doubleValue,
                amperage: number("Amperage")?.uint64Value
            ),
            adapterWatts: (adapter?["Watts"] as? NSNumber).flatMap { $0.doubleValue > 0 ? $0.doubleValue : nil },
            external: number("ExternalConnected")?.boolValue,
            charging: number("IsCharging")?.boolValue
        )
    }
}
