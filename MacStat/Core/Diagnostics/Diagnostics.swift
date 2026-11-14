import Foundation
import IOKit
import Darwin

nonisolated enum ThermalStatus: Int, Codable, Sendable {
    case normal, elevated, high, critical
    init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .normal
        case .fair: self = .elevated
        case .serious: self = .high
        case .critical: self = .critical
        @unknown default: self = .elevated
        }
    }
    var title: String { ["Normal", "Elevated", "High", "Critical"][rawValue] }
}

nonisolated struct BatteryReading: Equatable, Sendable {
    var cycles: Int?
    var health: Double?
    var watts: Double?
    var adapterWatts: Double?
    var external: Bool
    var charging: Bool

    static func health(maximum: Double?, design: Double?) -> Double? {
        guard let maximum, let design, maximum > 0, design > 0 else { return nil }
        return maximum / design * 100
    }
    static func read() -> Self? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let data = properties?.takeRetainedValue() as? [String: Any] else { return nil }
        func number(_ key: String) -> NSNumber? { data[key] as? NSNumber }
        let current = number("Amperage").map { Int64(bitPattern: $0.uint64Value) }
        let watts = current.flatMap { current in number("Voltage").map { $0.doubleValue * Double(current) / 1e6 } }
        return Self(cycles: number("CycleCount")?.intValue,
                    health: health(maximum: number("AppleRawMaxCapacity")?.doubleValue, design: number("DesignCapacity")?.doubleValue),
                    watts: watts,
                    adapterWatts: ((data["AdapterDetails"] as? [String: Any])?["Watts"] as? NSNumber)?.doubleValue,
                    external: number("ExternalConnected")?.boolValue ?? false,
                    charging: number("IsCharging")?.boolValue ?? false)
    }
}

nonisolated enum MemoryPressure: Int, Sendable {
    case normal = 1, warning = 2, critical = 4
    static func read() -> Self? {
        var value: Int32 = 0
        var size = MemoryLayout.size(ofValue: value)
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &value, &size, nil, 0) == 0 else { return nil }
        return Self(rawValue: Int(value))
    }
}
